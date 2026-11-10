#!/usr/bin/env python3
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/terraform.yml"


class ApplyWorkflowTests(unittest.TestCase):
    def test_apply_destroys_the_windows_vm_instead_of_recreating_it(self):
        workflow = WORKFLOW.read_text()
        main = (ROOT / "main.tf").read_text()
        self.assertNotIn(
            "libvirt_domain",
            main,
            "The Windows domain must stay out of main.tf or the next apply creates it again",
        )
        self.assertIn(
            'source  = "dmacvicar/libvirt"',
            main,
            "The libvirt provider has to stay so apply can destroy the VM still recorded in state",
        )
        self.assertNotIn(
            'sudo cp "$SRC" "$DST"',
            workflow,
            "Apply must not stage the Windows ISO back into the pool",
        )
        self.assertLess(
            workflow.index('sudo rm -f "$DST"'),
            workflow.index("Terraform plan"),
            "The staged ISO must leave the pool before Terraform deletes that pool",
        )
        self.assertNotIn(
            "undefine windows-srv-test",
            workflow,
            "windows-srv-test is still in Terraform state, so the workflow must not undefine it before apply",
        )


if __name__ == "__main__":
    unittest.main()
