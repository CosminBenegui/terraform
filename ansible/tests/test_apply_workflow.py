#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/terraform.yml"


class ApplyWorkflowTests(unittest.TestCase):
    def test_apply_creates_the_windows_vm_and_keeps_the_iso(self):
        workflow = WORKFLOW.read_text()
        main = (ROOT / "main.tf").read_text()
        self.assertIn(
            'resource "libvirt_domain" "windows_server"',
            main,
            "Terraform must create the Windows Server domain",
        )
        self.assertIn(
            'sudo cp "$SRC" "$DST"',
            workflow,
            "The workflow must stage a copy of the ISO into the libvirt pool",
        )
        self.assertNotIn(
            'sudo rm -f "$SRC"',
            workflow,
            "The workflow must not delete the ISO in Downloads",
        )
        self.assertNotIn(
            'sudo rm -f "$DST"',
            workflow,
            "The workflow must not delete the staged ISO",
        )
        self.assertIn(
            "grep -qx 'libvirt_domain.windows_server'",
            workflow,
            "windows-srv-test may be undefined only when it is not already in Terraform state",
        )
        self.assertNotIn(
            "ansible-playbook site.yml",
            workflow,
            "The apply workflow must not run the media playbook",
        )
        self.assertNotIn(
            "install -y ansible",
            workflow,
            "The apply workflow must not install Ansible",
        )
        self.assertLess(
            workflow.index("Terraform init"),
            workflow.index("Terraform plan"),
            "Init must run before plan",
        )
        self.assertLess(
            workflow.index("Terraform plan"),
            workflow.index("terraform apply -auto-approve -input=false tfplan"),
            "Apply must use the plan that was just created",
        )
        self.assertIn(
            "xsltproc",
            workflow,
            "The Windows domain XSLT needs xsltproc on the host",
        )


if __name__ == "__main__":
    unittest.main()
