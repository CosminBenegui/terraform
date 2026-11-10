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


if __name__ == "__main__":
    unittest.main()
