---
name: homelab-terraform
description: >-
  Operate this Debian homelab Terraform lesson: one Windows Server VM on
  libvirt. Use when editing Terraform, GitHub Actions, or the Windows domain.
  There is no Ansible and no media stack.
---

# Windows VM Terraform

Replies stay in English. Stay on `main` for lab work. Do not check out or merge `interview-labs`.

## Where things run

- Lab host: Debian bare metal `192.168.0.120`, user `cosmin`. SSH only when the user asks. Password auth; never commit the password.
- This checkout is not the lab host. Terraform state is only on the host at `/home/cosmin/terraform-project`, workspace `test`. No S3, no remote backend.
- Runner `debian-terraform` (`~/actions-runner`, labels `self-hosted, terraform-vm`) applies on push to `main`. `workflow_dispatch` input `action` is `plan` or `apply`. Plan does not apply.
- Destroy is `.github/workflows/terraform-destroy.yml`, `workflow_dispatch` only. Input `confirm` must be exactly `destroy`.
- `gh` is not installed. Never `git config`.

## What Terraform owns

`main.tf` defines the Windows Server: pool `default`, network `win-internal-test`, disk `windows-srv-disk-test.qcow2` (250 GiB), and domain `windows-srv-test`. The libvirt URI is `qemu:///system`.

There is no Ansible. Do not add playbooks, `ansible-playbook`, or Docker containers while this lesson is the Windows VM. Keep the `kreuzwerker/docker` provider until the `test` state no longer contains Docker resources. Terraform cannot read that state without it.

## Do not regress

- The Windows ISO stays at `/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso`. Never delete that file. Stage a copy into `/var/lib/libvirt/images` for QEMU. Do not `virsh undefine windows-srv-test` while it is in Terraform state.
- Tests in `tests/` must keep an assert message. Clean up unused code. Do not commit `__pycache__` or `*.pyc`.

## Change flow

1. Edit on `main`.
2. Commit and push only when the user asked.
3. Do not hand-edit the host to simulate a run.

Known failure strings and the fix that must stay in git: [pitfalls.md](pitfalls.md).
