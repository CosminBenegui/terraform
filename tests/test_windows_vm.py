#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class WindowsVmTests(unittest.TestCase):
    def test_main_tf_defines_only_the_windows_vm(self):
        main = (ROOT / "main.tf").read_text()
        for name in (
            'resource "libvirt_pool" "default"',
            'resource "libvirt_network" "internal_net"',
            'resource "libvirt_volume" "windows_os_disk"',
            'resource "libvirt_domain" "windows_server"',
        ):
            self.assertIn(name, main, f"Terraform must define {name}")
        self.assertIn(
            "/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso",
            main,
            "The original installer ISO must stay in Downloads",
        )
        for gone in (
            "ansible-playbook",
            "provider \"docker\"",
            "docker_container",
            "kreuzwerker/docker",
        ):
            self.assertNotIn(gone, main, f"The Windows lesson must not keep {gone}")

    def test_workflows_do_not_run_ansible(self):
        texts = [
            path.read_text()
            for path in (ROOT / ".github" / "workflows").glob("*.yml")
        ]
        combined = "\n".join(texts)
        self.assertNotIn(
            "ansible-playbook",
            combined,
            "GitHub Actions must not run Ansible",
        )
        self.assertNotIn(
            "apt-get install -y ansible",
            combined,
            "The runner must not install Ansible",
        )
        self.assertIn(
            "SERVER_EVAL_x64FRE_en-us.iso",
            (ROOT / ".github" / "workflows" / "terraform.yml").read_text(),
            "Apply must keep the Windows ISO in Downloads",
        )


if __name__ == "__main__":
    unittest.main()
