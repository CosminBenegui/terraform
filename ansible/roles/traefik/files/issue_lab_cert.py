#!/usr/bin/env python3
"""Issue a lab CA and a *.lab.home certificate. Existing keys stay in place."""

import subprocess
import sys
from pathlib import Path

DEFAULT_CERT_DIR = Path("/var/lib/lab/compose/traefik/certs")
DEFAULT_CA_COPY = Path("/var/lib/lab/certs/lab-ca.crt")
SANS = "DNS:*.lab.home,DNS:lab.home,IP:192.168.0.120"


def extension_text():
    return (
        "subjectAltName=" + SANS + "\n"
        "extendedKeyUsage=serverAuth\n"
        "keyUsage=digitalSignature,keyEncipherment\n"
    )


def _run(args):
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL)


def _write_ca(cert_dir):
    _run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-sha256",
            "-days",
            "3650",
            "-nodes",
            "-keyout",
            str(cert_dir / "lab-ca.key"),
            "-out",
            str(cert_dir / "lab-ca.crt"),
            "-subj",
            "/CN=lab.home CA",
        ]
    )


def _write_leaf(cert_dir):
    ext = cert_dir / "lab.home.ext"
    ext.write_text(extension_text())
    _run(
        [
            "openssl",
            "req",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(cert_dir / "lab.home.key"),
            "-out",
            str(cert_dir / "lab.home.csr"),
            "-subj",
            "/CN=lab.home",
        ]
    )
    _run(
        [
            "openssl",
            "x509",
            "-req",
            "-in",
            str(cert_dir / "lab.home.csr"),
            "-CA",
            str(cert_dir / "lab-ca.crt"),
            "-CAkey",
            str(cert_dir / "lab-ca.key"),
            "-CAcreateserial",
            "-out",
            str(cert_dir / "lab.home.crt"),
            "-days",
            "825",
            "-sha256",
            "-extfile",
            str(ext),
        ]
    )


def issue(cert_dir, copy_to=None):
    cert_dir = Path(cert_dir)
    cert_dir.mkdir(parents=True, exist_ok=True)
    ca_key = cert_dir / "lab-ca.key"
    ca_crt = cert_dir / "lab-ca.crt"
    leaf_key = cert_dir / "lab.home.key"
    leaf_crt = cert_dir / "lab.home.crt"
    created = False
    if ca_key.exists() ^ ca_crt.exists():
        raise SystemExit("lab CA key and certificate must be created together")
    if leaf_key.exists() ^ leaf_crt.exists():
        raise SystemExit("leaf key and certificate must be created together")
    if not ca_key.exists():
        _write_ca(cert_dir)
        created = True
    if not leaf_key.exists():
        _write_leaf(cert_dir)
        created = True
    ca_key.chmod(0o600)
    leaf_key.chmod(0o600)
    ca_crt.chmod(0o644)
    leaf_crt.chmod(0o644)
    if copy_to is not None:
        copy_to = Path(copy_to)
        copy_to.parent.mkdir(parents=True, exist_ok=True)
        copy_to.write_bytes(ca_crt.read_bytes())
        copy_to.chmod(0o644)
    return "created" if created else "unchanged"


def main():
    cert_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_CERT_DIR
    print(issue(cert_dir, DEFAULT_CA_COPY))


if __name__ == "__main__":
    main()
