# Terraform

One Windows Server VM, defined in `main.tf` and applied by the self-hosted runner on the Debian host.

## What Terraform creates

| Resource | Name |
| --- | --- |
| Storage pool | `default` at `/var/lib/libvirt/images` |
| Isolated network | `win-internal-test` (`10.30.0.0/16`, no uplink) |
| Disk | `windows-srv-disk-test.qcow2` (250 GiB) |
| Domain | `windows-srv-test` (2 vCPU, 4096 MB, VNC) |

The installer stays at `/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso`. Terraform copies it into the pool. The Downloads file is the original.

Workspace: `test`. State lives only on the host at `/home/cosmin/terraform-project`.

## See it

```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system vncdisplay windows-srv-test
```

Connect RealVNC to `192.168.0.120` on the port that command prints.

## Run it

GitHub → Actions → Terraform → Run workflow → `plan` or `apply`.

Read [LEARN.md](LEARN.md) for what each block in `main.tf` does.
