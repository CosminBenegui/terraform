#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class MonitorTests(unittest.TestCase):
    def test_glances_shows_the_host_and_containers(self):
        compose = (ROOT / "roles/monitor/templates/compose.yml.j2").read_text()
        conf = (ROOT / "roles/monitor/templates/glances.conf.j2").read_text()
        site = (ROOT / "site.yml").read_text()
        self.assertIn(
            "image: nicolargo/glances:latest",
            compose,
            "Glances publishes a latest tag and that image includes the web UI and Docker support",
        )
        self.assertIn(
            'GLANCES_OPT: "-C /glances/conf/glances.conf -w"',
            compose,
            "Glances must start in web mode and load the lab config",
        )
        self.assertIn("pid: host", compose, "Glances must see the host processes, not only its own")
        self.assertIn(
            "network_mode: host",
            compose,
            "Glances must share the host network so the NIC stats are the Debian host",
        )
        self.assertNotIn(
            "networks:",
            compose,
            "Glances cannot set networks together with network_mode host",
        )
        self.assertIn(
            "/var/run/docker.sock:/var/run/docker.sock:ro",
            compose,
            "Glances must read the Docker socket so the container list is the media stack",
        )
        self.assertIn("[containers]\ndisable=False", conf, "The containers panel must be turned on")
        self.assertLess(
            site.index("- monitor"),
            site.index("- traefik"),
            "Glances has to be rendered before Traefik starts routing monitor.lab.home",
        )

    def test_glances_is_named_in_dns_traefik_and_authentik(self):
        hosts = (ROOT / "roles/dns/tasks/main.yml").read_text()
        traefik = (ROOT / "roles/traefik/defaults/main.yml").read_text()
        authentik = (ROOT / "roles/authentik/defaults/main.yml").read_text()
        firewall = (ROOT / "roles/firewall/tasks/main.yml").read_text()
        self.assertIn(
            "monitor.lab.home",
            hosts,
            "The Debian host must resolve monitor.lab.home to 192.168.0.120",
        )
        self.assertIn(
            '{ slug: glances, host: monitor.lab.home, upstream: "http://10.20.0.1:61208" }',
            traefik,
            "Traefik must reach Glances on the Docker bridge gateway because Glances uses the host network",
        )
        self.assertIn(
            "{ name: Glances, slug: glances, host: monitor.lab.home }",
            authentik,
            "Authentik must protect Glances with the same admin login as the other apps",
        )
        self.assertIn("61208/tcp", firewall, "The Glances web port must stay allowed when ufw is already active")

    def test_netdata_stays_removed(self):
        traefik = (ROOT / "roles/traefik/defaults/main.yml").read_text()
        authentik = (ROOT / "roles/authentik/defaults/main.yml").read_text()
        docker_host = (ROOT / "roles/docker_host/tasks/main.yml").read_text()
        blueprint = (ROOT / "roles/authentik/templates/blueprint.yaml.j2").read_text()
        self.assertNotIn("netdata", traefik, "Traefik must not route to the removed Netdata container")
        self.assertNotIn("netdata", authentik, "Authentik must not publish a Netdata application")
        self.assertIn(
            "docker rm -f netdata",
            docker_host,
            "Apply must stop the Netdata container left on the host",
        )
        self.assertLess(
            blueprint.index("state: absent"),
            blueprint.index("slug: netdata"),
            "The Netdata Authentik application must be marked absent",
        )

    def test_traefik_still_mounts_its_config_directory(self):
        traefik_compose = (ROOT / "roles/traefik/templates/compose.yml.j2").read_text()
        self.assertIn(
            "/var/lib/lab/compose/traefik:/etc/traefik:ro",
            traefik_compose,
            "Traefik must mount the config directory, or a replaced dynamic.yml stays invisible",
        )


if __name__ == "__main__":
    unittest.main()
