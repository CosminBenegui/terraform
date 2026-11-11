#!/usr/bin/env python3
import pathlib
import unittest

WORKFLOW = (
    pathlib.Path(__file__).resolve().parents[2]
    / ".github/workflows/terraform-destroy.yml"
)


class DestroyWorkflowTests(unittest.TestCase):
    def test_destroy_runs_only_when_confirmed(self):
        text = WORKFLOW.read_text()
        self.assertNotIn(
            "push:",
            text,
            "Destroy must not run on push to main",
        )
        self.assertIn(
            "workflow_dispatch:",
            text,
            "Destroy must be startable from the Actions tab",
        )
        self.assertIn(
            "inputs.confirm == 'destroy'",
            text,
            "The remote run must require the word destroy before it deletes resources",
        )
        self.assertIn(
            "terraform destroy -auto-approve -input=false",
            text,
            "The remote workflow has to run terraform destroy on the self-hosted runner",
        )
        self.assertIn(
            "terraform.tfstate.d",
            text,
            "Destroy must keep the workspace state when it copies the checkout",
        )
        self.assertLess(
            text.index('IMG=/var/lib/libvirt/images'),
            text.index("terraform destroy -auto-approve -input=false"),
            "Every ISO must leave the images directory before destroy deletes the pool",
        )
        self.assertIn(
            "-name '*.iso'",
            text,
            "Destroy must clear every ISO, not one hardcoded filename",
        )
        self.assertIn(
            "sudo find",
            text,
            "The images directory is not listable by the runner, so cleanup must list it with sudo",
        )
        self.assertIn(
            '[ -d "$IMG" ]',
            text,
            "A missing images directory must not fail destroy",
        )
        self.assertNotIn(
            'sudo cp ',
            text,
            "Destroy must not copy an ISO back into the images directory",
        )


if __name__ == "__main__":
    unittest.main()
