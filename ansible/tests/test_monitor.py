#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class MonitorTests(unittest.TestCase):
    def test_netdata_is_on_the_media_network_without_a_host_port(self):
        compose = (ROOT / "roles/monitor/templates/compose.yml.j2").read_text()
        site = (ROOT / "site.yml").read_text()
        self.assertIn(
            "image: netdata/netdata:latest",
            compose,
            "Netdata publishes a latest tag and that is the image the lab runs",
        )
        self.assertIn(
            "/var/run/docker.sock:/var/run/docker.sock:ro",
            compose,
            "Netdata must read the Docker socket so it can see the other containers",
        )
        self.assertNotIn(
            "19999:",
            compose,
            "Netdata stays off the host ports; Traefik and Authentik are the way in",
        )
        self.assertLess(
            site.index("- monitor"),
            site.index("- traefik"),
            "Netdata has to exist before Traefik starts routing monitor.lab.home",
        )

    def test_monitor_is_named_in_dns_traefik_and_authentik(self):
        hosts = (ROOT / "roles/dns/tasks/main.yml").read_text()
        traefik = (ROOT / "roles/traefik/defaults/main.yml").read_text()
        authentik = (ROOT / "roles/authentik/defaults/main.yml").read_text()
        self.assertIn(
            "monitor.lab.home",
            hosts,
            "The Debian host must resolve monitor.lab.home to 192.168.0.120",
        )
        self.assertIn(
            '{ slug: netdata, host: monitor.lab.home, upstream: "http://netdata:19999" }',
            traefik,
            "Traefik must forward monitor.lab.home to the Netdata container",
        )
        self.assertIn(
            "{ name: Netdata, slug: netdata, host: monitor.lab.home }",
            authentik,
            "Authentik must protect Netdata with the same admin login as the other apps",
        )


if __name__ == "__main__":
    unittest.main()
