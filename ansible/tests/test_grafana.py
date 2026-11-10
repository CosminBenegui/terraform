#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class GrafanaTests(unittest.TestCase):
    def test_grafana_keeps_glances_and_adds_logs(self):
        glances = (ROOT / "roles/monitor/templates/compose.yml.j2").read_text()
        compose = (ROOT / "roles/grafana/templates/compose.yml.j2").read_text()
        site = (ROOT / "site.yml").read_text()
        self.assertIn(
            "image: nicolargo/glances:latest",
            glances,
            "Glances stays in the monitor role",
        )
        self.assertNotIn(
            "grafana",
            glances,
            "Grafana must not replace the Glances compose file",
        )
        self.assertLess(
            site.index("- monitor"),
            site.index("- grafana"),
            "Glances still starts before Grafana",
        )
        self.assertLess(
            site.index("- grafana"),
            site.index("- traefik"),
            "Grafana must be running before Traefik routes grafana.lab.home",
        )
        self.assertIn("image: grafana/grafana:latest", compose, "Grafana publishes a latest tag")
        self.assertIn("image: grafana/loki:latest", compose, "Loki stores the container logs")
        self.assertIn("image: prom/prometheus:latest", compose, "Prometheus stores the host metrics")
        self.assertIn("image: grafana/alloy:latest", compose, "Alloy collects logs and host metrics")
        self.assertIn(
            "GF_AUTH_DISABLE_LOGIN_FORM: \"true\"",
            compose,
            "Grafana must not ask for a second password after Authentik",
        )
        self.assertIn(
            "GF_AUTH_PROXY_HEADER_NAME: X-authentik-username",
            compose,
            "Grafana must accept the user Authentik already authenticated",
        )
        self.assertNotIn(
            '"3000:3000"',
            compose,
            "Grafana's port stays off the host so the auth header cannot be spoofed from the LAN",
        )

    def test_grafana_is_named_in_dns_traefik_and_authentik(self):
        hosts = (ROOT / "roles/dns/tasks/main.yml").read_text()
        traefik = (ROOT / "roles/traefik/defaults/main.yml").read_text()
        authentik = (ROOT / "roles/authentik/defaults/main.yml").read_text()
        datasources = (
            ROOT / "roles/grafana/files/provisioning/datasources/datasources.yml"
        ).read_text()
        alloy = (ROOT / "roles/grafana/files/config.alloy").read_text()
        self.assertIn(
            "grafana.lab.home",
            hosts,
            "The Debian host must resolve grafana.lab.home to 192.168.0.120",
        )
        self.assertIn(
            '{ slug: grafana, host: grafana.lab.home, upstream: "http://grafana:3000" }',
            traefik,
            "Traefik must send grafana.lab.home to the Grafana container",
        )
        self.assertIn(
            "{ name: Grafana, slug: grafana, host: grafana.lab.home }",
            authentik,
            "Authentik must protect Grafana with the same login as the other apps",
        )
        self.assertIn("url: http://prometheus:9090", datasources, "Grafana must query Prometheus")
        self.assertIn("url: http://loki:3100", datasources, "Grafana must query Loki")
        self.assertIn(
            'target_label  = "container"',
            alloy,
            "Container logs need a container label so the Lab dashboard can query them",
        )


if __name__ == "__main__":
    unittest.main()
