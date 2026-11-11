#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
ANSIBLE = ROOT / "ansible"


class TerraformCreatesTests(unittest.TestCase):
    def test_main_tf_creates_the_stack_and_the_windows_vm(self):
        main = (ROOT / "main.tf").read_text()
        rule = (ROOT / ".cursor/rules/terraform-creates.mdc").read_text()
        for name in (
            'resource "docker_network" "media"',
            'resource "docker_container" "plex"',
            'resource "docker_container" "prowlarr"',
            'resource "docker_container" "radarr"',
            'resource "docker_container" "sonarr"',
            'resource "docker_container" "seerr"',
            'resource "docker_container" "qbittorrent"',
            'resource "docker_container" "glances"',
            'resource "docker_container" "traefik"',
            'resource "docker_container" "authentik"',
            'resource "docker_container" "grafana"',
            'resource "libvirt_domain" "windows_server"',
        ):
            self.assertIn(name, main, f"Terraform must create {name}")
        self.assertIn(
            "ansible-playbook site.yml",
            main,
            "Terraform must call Ansible to write config before creating containers",
        )
        self.assertIn(
            "ansible-playbook site-configure.yml",
            main,
            "Terraform must call Ansible to link apps after the containers exist",
        )
        self.assertIn(
            "Terraform creates",
            rule,
            "The repo rule must say Terraform creates the stack",
        )
        self.assertIn(
            "Ansible configures",
            rule,
            "The repo rule must say Ansible only configures the stack",
        )

    def test_ansible_roles_do_not_create_the_stack(self):
        tasks = []
        for path in (ANSIBLE / "roles").rglob("tasks/main.yml"):
            tasks.append(path.read_text())
        for path in (ANSIBLE / "site.yml", ANSIBLE / "site-configure.yml"):
            tasks.append(path.read_text())
        combined = "\n".join(tasks)
        for forbidden in (
            "docker compose up",
            "docker network create",
            "docker volume create",
            "docker run",
            "virsh define",
        ):
            self.assertNotIn(
                forbidden,
                combined,
                f"Ansible must not create the stack with {forbidden}",
            )

    def test_site_configure_migrates_authentik_before_the_worker_starts(self):
        text = (ANSIBLE / "site-configure.yml").read_text()
        self.assertNotIn(
            "docker restart authentik authentik-worker",
            text,
            "Restarting the worker with the server locks the empty-database migration",
        )
        self.assertIn(
            "docker stop authentik-worker",
            text,
            "The worker must be stopped before the server migrates",
        )
        self.assertLess(
            text.index("docker restart authentik"),
            text.index("docker start authentik-worker"),
            "The server must restart and become ready before the worker starts",
        )
        self.assertIn(
            "/-/health/ready/",
            text,
            "The worker must wait until Authentik reports ready",
        )


if __name__ == "__main__":
    unittest.main()
