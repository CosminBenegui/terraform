#!/usr/bin/env python3
import pathlib
import unittest

WORKFLOW = (
    pathlib.Path(__file__).resolve().parents[2]
    / ".github/workflows/terraform-plan.yml"
)


class PlanWorkflowTests(unittest.TestCase):
    def test_pull_request_plans_and_starts_the_agents(self):
        text = WORKFLOW.read_text()
        self.assertIn(
            "pull_request:",
            text,
            "A pull request must start this workflow",
        )
        self.assertIn(
            "@pipeline-relay",
            text,
            "The plan comment must mention pipeline-relay so the agents start",
        )
        self.assertIn(
            "ask_platform",
            text,
            "The start comment must send the plan to the platform agent",
        )
        self.assertIn(
            "ask_network",
            text,
            "The start comment must send the plan to the network agent",
        )
        self.assertIn(
            "Do not call hand_to_coder",
            text,
            "A pull request plan must not hand work to the coding agent",
        )
        self.assertIn(
            "terraform plan -input=false -no-color -lock=false",
            text,
            "The workflow must print a plan and must not lock the live state",
        )
        self.assertIn(
            "github.event.pull_request.head.repo.full_name == github.repository",
            text,
            "Fork pull requests must not run on the self-hosted runner",
        )
        self.assertNotIn(
            "terraform apply",
            text,
            "A pull request must not apply",
        )
        self.assertNotIn(
            "ansible-playbook",
            text,
            "A pull request plan must not run Ansible against the host",
        )


if __name__ == "__main__":
    unittest.main()
