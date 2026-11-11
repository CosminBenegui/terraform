# Learn this Windows VM

Terraform compares `main.tf` with the libvirt host and makes the host match the file.

## The four resources

1. `libvirt_pool.default` is the folder where QEMU keeps disk images.
2. `libvirt_network.internal_net` is a network with no route to the LAN. The VM also has a second NIC on the host's `default` network, which is how you reach it.
3. `libvirt_volume.windows_os_disk` is the 250 GiB virtual hard disk.
4. `libvirt_domain.windows_server` is the VM. It boots from that disk, with the installer ISO as a second disk.

`local.env` is `test`, so the domain name is `windows-srv-test`.

## What apply does

A push to `main` runs on the Debian host, in workspace `test`. `terraform plan` shows the difference. `terraform apply` creates or changes only what the plan lists.

The pool's `provisioner` runs a copy command after the pool exists. It copies the ISO from Downloads into `/var/lib/libvirt/images`. It does not delete the file in Downloads.

## What to leave alone

- `/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso`
- `windows-srv-test` while Terraform still has it in state

Destroy is a separate workflow. The confirm word is `destroy`.
