#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


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
        self.assertNotIn(
            "ghcr.io/goauthentik/server:latest",
            compose,
            "The missing latest tag is what made the runner fail the Authentik pull",
        )


if __name__ == "__main__":
    unittest.main()
