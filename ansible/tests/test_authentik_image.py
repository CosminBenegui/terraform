#!/usr/bin/env python3
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "roles/authentik/files"))
import postgres_volume  # noqa: E402


def _hcl_block(text, header):
    start = text.index(header)
    brace = text.index("{", start)
    depth = 0
    for index in range(brace, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    raise AssertionError(f"unclosed block {header}")


def _compose_service(text, name):
    lines = text.splitlines(keepends=True)
    start = None
    for index, line in enumerate(lines):
        if line.startswith(f"  {name}:"):
            start = index
            break
    if start is None:
        raise AssertionError(f"missing compose service {name}")
    end = len(lines)
    for index in range(start + 1, len(lines)):
        line = lines[index]
        if line.strip() and not line.startswith(" "):
            end = index
            break
        if line.startswith("  ") and not line.startswith("   ") and line.strip():
            end = index
            break
    return "".join(lines[start:end])


class AuthentikImageTests(unittest.TestCase):
    def test_authentik_image_is_a_published_tag(self):
        defaults = (ROOT / "roles/authentik/defaults/main.yml").read_text()
        compose = (ROOT / "roles/authentik/templates/compose.yml.j2").read_text()
        self.assertIn(
            'authentik_image: "ghcr.io/goauthentik/server:2026.8.5"',
            defaults,
            "Authentik does not publish a latest tag; pin the newest published release",
        )
        self.assertEqual(
            compose.count('image: "{{ authentik_image }}"'),
            2,
            "Server and worker must use the same pinned Authentik image",
        )
        self.assertEqual(
            compose.count("AUTHENTIK_HOST: https://auth.lab.home"),
            2,
            "Without AUTHENTIK_HOST the browser is sent to http://localhost and the page is blank",
        )
        blueprint = (ROOT / "roles/authentik/templates/blueprint.yaml.j2").read_text()
        self.assertIn(
            "authentik_host_browser: https://auth.lab.home",
            blueprint,
            "The outpost must send the browser to auth.lab.home, not localhost",
        )
        self.assertNotIn(
            "ghcr.io/goauthentik/server:latest",
            compose,
            "The missing latest tag is what made the runner fail the Authentik pull",
        )
        self.assertIn(
            "authentik-db:/var/lib/postgresql\n",
            compose,
            "Postgres 18 stores the cluster under /var/lib/postgresql, not /var/lib/postgresql/data",
        )
        self.assertNotIn(
            "/var/lib/postgresql/data",
            compose,
            "The old data mount is why authentik-postgresql keeps restarting",
        )

    def test_authentik_dev_shm_is_an_uncapped_tmpfs(self):
        main = (ROOT.parent / "main.tf").read_text()
        compose = (ROOT / "roles/authentik/templates/compose.yml.j2").read_text()
        for name in ("authentik", "authentik_worker"):
            block = _hcl_block(main, f'resource "docker_container" "{name}"')
            self.assertNotIn(
                "shm_size",
                block,
                f"{name} must not set shm_size; that caps /dev/shm",
            )
            for limit in ("memory", "memory_swap", "memory_reservation"):
                self.assertNotIn(
                    limit,
                    block,
                    f"{name} must not set a {limit} limit",
                )
            self.assertIn(
                '"/dev/shm" = ""',
                block,
                f"{name} must mount /dev/shm as a tmpfs with no size option",
            )
        for name in ("server", "worker"):
            service = _compose_service(compose, name)
            self.assertNotIn(
                "shm_size",
                service,
                f"The {name} compose service must not set shm_size",
            )
            for limit in ("mem_limit", "memory:", "size="):
                self.assertNotIn(
                    limit,
                    service,
                    f"The {name} compose service must not set {limit}",
                )
            self.assertIn(
                "- /dev/shm\n",
                service,
                f"The {name} compose service must mount /dev/shm as a tmpfs with no size option",
            )

    def test_only_the_pre_18_volume_is_removed(self):
        self.assertEqual(
            postgres_volume.legacy_volume_name(
                [{"Destination": "/var/lib/postgresql/data", "Name": "authentik_authentik-db"}]
            ),
            "authentik_authentik-db",
            "A volume still mounted at /var/lib/postgresql/data has to be removed before Postgres 18 will start",
        )
        self.assertEqual(
            postgres_volume.legacy_volume_name(
                [{"Destination": "/var/lib/postgresql", "Name": "authentik_authentik-db"}]
            ),
            "",
            "A volume already mounted at /var/lib/postgresql must be kept",
        )


if __name__ == "__main__":
    unittest.main()
