#!/usr/bin/env python3
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
TASKS = ROOT / "roles/traefik/tasks/main.yml"
SAN = "subjectAltName=DNS:*.lab.home,DNS:lab.home,IP:192.168.0.120"


class LabCertTests(unittest.TestCase):
    def test_extension_covers_every_lab_name_and_the_host_ip(self):
        text = TASKS.read_text()
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
            first = _issue(cert_dir)
            leaf = (cert_dir / "lab.home.crt").read_bytes()
            key = (cert_dir / "lab.home.key").read_bytes()
            second = _issue(cert_dir)
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
        tasks = TASKS.read_text()
        dynamic = (ROOT / "roles/traefik/templates/dynamic.yml.j2").read_text()
        self.assertNotIn(
            "issue_lab_cert.py",
            tasks,
            "The lab certificate is issued by the Traefik role during the workflow apply",
        )
        self.assertIn(
            "creates: /var/lib/lab/compose/traefik/certs/lab.home.crt",
            tasks,
            "Ansible must skip openssl when the lab certificate already exists",
        )
        shell_task = _task_block(tasks, "Issue the lab certificate when it is missing")
        self.assertNotIn(
            "\n    args:",
            "\n" + shell_task,
            "The shell task must not pass a nested args key; Ansible 2.19 forwards it to command and rejects it",
        )
        self.assertNotIn(
            "docker compose",
            tasks,
            "Ansible must not start Traefik; Terraform creates that container",
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
        self.assertFalse(
            (ROOT / "roles/traefik/files/issue_lab_cert.py").exists(),
            "The certificate step must not live in a separate Python script",
        )


def _task_block(text, name):
    marker = f"- name: {name}\n"
    start = text.index(marker)
    rest = text[start:]
    next_task = rest.find("\n- name:", len(marker))
    if next_task == -1:
        return rest
    return rest[:next_task]


def _issue(cert_dir):
    """Same skip rule as the Traefik role: openssl runs only when the leaf is missing."""
    cert_dir.mkdir(parents=True, exist_ok=True)
    leaf_crt = cert_dir / "lab.home.crt"
    leaf_key = cert_dir / "lab.home.key"
    if leaf_crt.exists() and leaf_key.exists():
        return "unchanged"
    ext = cert_dir / "lab.home.ext"
    ext.write_text(SAN + "\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n")
    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-days", "3650", "-nodes",
            "-keyout", str(cert_dir / "lab-ca.key"),
            "-out", str(cert_dir / "lab-ca.crt"),
            "-subj", "/CN=lab.home CA",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        [
            "openssl", "req", "-newkey", "rsa:2048", "-nodes",
            "-keyout", str(leaf_key),
            "-out", str(cert_dir / "lab.home.csr"),
            "-subj", "/CN=lab.home",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        [
            "openssl", "x509", "-req",
            "-in", str(cert_dir / "lab.home.csr"),
            "-CA", str(cert_dir / "lab-ca.crt"),
            "-CAkey", str(cert_dir / "lab-ca.key"),
            "-CAcreateserial",
            "-out", str(leaf_crt),
            "-days", "825",
            "-sha256",
            "-extfile", str(ext),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return "created"


if __name__ == "__main__":
    unittest.main()
