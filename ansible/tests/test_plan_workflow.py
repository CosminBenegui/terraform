#!/usr/bin/env python3
import pathlib
import unittest

WORKFLOW = (
    pathlib.Path(__file__).resolve().parents[2]
    / ".github/workflows/terraform-plan.yml"
)


class PlanWorkflowTests(unittest.TestCase):
    def test_pull_requests_plan_without_applying(self):
        text = WORKFLOW.read_text()
        self.assertIn(
            "pull_request:",
            text,
            "The plan workflow must run on pull requests",
        )
        self.assertIn(
            "terraform plan -input=false -no-color -lock=false",
            text,
            "The plan workflow must print a plan and must not lock the live state",
        )
        self.assertIn(
            "actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8",
            text,
            "Checkout must be pinned to the v5.0.0 commit",
        )
        self.assertIn(
            "github.event.pull_request.head.repo.full_name == github.repository",
            text,
            "Fork pull requests must not run on the self-hosted runner",
        )
        self.assertIn(
            "contents: read",
            text,
            "The plan job must not receive write access to the repository",
        )
        self.assertNotIn(
            "terraform apply",
            text,
            "A pull request plan must not apply",
        )
        self.assertNotIn(
            "terraform destroy",
            text,
            "A pull request plan must not destroy",
        )
        self.assertNotIn(
            "ansible-playbook",
            text,
            "A pull request plan must not run Ansible against the host",
        )
        self.assertNotIn(
            'rm -rf "$PROJECT_DIR"',
            text,
            "A pull request plan must not delete the live Terraform directory",
        )


if __name__ == "__main__":
    unittest.main()
