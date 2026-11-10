#!/usr/bin/env python3
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "roles/authentik/files"))
import postgres_volume  # noqa: E402


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
