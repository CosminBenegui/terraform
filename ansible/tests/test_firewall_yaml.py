#!/usr/bin/env python3
import pathlib
import unittest


class FirewallYamlTests(unittest.TestCase):
    def test_ufw_when_quotes_the_status_colon(self):
        text = (
            pathlib.Path(__file__).resolve().parents[1]
            / "roles/firewall/tasks/main.yml"
        ).read_text()
        self.assertIn(
            "when: \"ufw_status.rc == 0 and 'Status: active' in ufw_status.stdout\"",
            text,
            "Ansible 2.19 rejects an unquoted 'Status: active' colon in the ufw when clause",
        )


if __name__ == "__main__":
    unittest.main()
