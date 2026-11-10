#!/usr/bin/env python3
import pathlib
import unittest

WORKFLOW = (
    pathlib.Path(__file__).resolve().parents[2] / ".github/workflows/terraform.yml"
)


class ApplyWorkflowTests(unittest.TestCase):
    def test_iso_copy_creates_the_pool_directory(self):
        text = WORKFLOW.read_text()
        mkdir_at = text.index("sudo mkdir -p /var/lib/libvirt/images")
        copy_at = text.index('sudo cp "$SRC" "$DST"')
        self.assertLess(
            mkdir_at,
            copy_at,
            "Destroy deletes /var/lib/libvirt/images, so apply must recreate it before copying the ISO",
        )


if __name__ == "__main__":
    unittest.main()
