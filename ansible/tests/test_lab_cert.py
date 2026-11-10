#!/usr/bin/env python3
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "roles/traefik/files"))
import issue_lab_cert  # noqa: E402


class LabCertTests(unittest.TestCase):
    def test_extension_covers_every_lab_name_and_the_host_ip(self):
        text = issue_lab_cert.extension_text()
        self.assertIn(
            "DNS:*.lab.home",
            text,
            "One certificate has to match radarr.lab.home, grafana.lab.home, and the other names",
        )
        self.assertIn(
            "DNS:lab.home",
            text,
            "The apex name has to be on the certificate as well as the wildcard",
        )
        self.assertIn(
            "IP:192.168.0.120",
            text,
            "https://192.168.0.120 must present the lab certificate",
        )

    def test_issue_creates_once_and_then_leaves_the_key_alone(self):
        with tempfile.TemporaryDirectory() as tmp:
            cert_dir = pathlib.Path(tmp)
            first = issue_lab_cert.issue(cert_dir)
            leaf = (cert_dir / "lab.home.crt").read_bytes()
            key = (cert_dir / "lab.home.key").read_bytes()
            second = issue_lab_cert.issue(cert_dir)
            text = subprocess.check_output(
                ["openssl", "x509", "-in", str(cert_dir / "lab.home.crt"), "-noout", "-ext", "subjectAltName"],
                text=True,
            )
            self.assertEqual(leaf, (cert_dir / "lab.home.crt").read_bytes(), "The leaf certificate bytes must stay the same")
            self.assertEqual(key, (cert_dir / "lab.home.key").read_bytes(), "The leaf private key must stay the same")
        self.assertEqual(first, "created", "A missing lab certificate must be created")
        self.assertEqual(second, "unchanged", "A second run must not rotate the certificate the browsers already trust")
        self.assertIn("*.lab.home", text, "The issued certificate must contain the wildcard SAN")
        self.assertIn("192.168.0.120", text, "The issued certificate must contain the lab host IP")

    def test_traefik_uses_the_issued_certificate(self):
        tasks = (ROOT / "roles/traefik/tasks/main.yml").read_text()
        dynamic = (ROOT / "roles/traefik/templates/dynamic.yml.j2").read_text()
        self.assertLess(
            tasks.index("issue_lab_cert.py"),
            tasks.index("docker compose"),
            "The certificate must exist before Traefik starts",
        )
        self.assertIn(
            "certFile: /etc/traefik/certs/lab.home.crt",
            dynamic,
            "Traefik must serve the lab certificate instead of its generated default",
        )
        self.assertIn(
            "keyFile: /etc/traefik/certs/lab.home.key",
            dynamic,
            "Traefik must load the matching private key",
        )


if __name__ == "__main__":
    unittest.main()
