# Pitfalls

| What you see | What has to stay true |
| --- | --- |
| The VM has no installer disc | The original ISO stays at `/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso`. The pool provisioner copies it to `/var/lib/libvirt/images`. Never delete the Downloads file. |
| `virsh undefine windows-srv-test` while Terraform still tracks it | Leave that domain alone. Undefine only names Terraform does not own, such as `windows-srv` and `windows-server-test`. |
| Pool delete fails because the ISO is in the pool directory | Move or remove only the staged copy. Keep the Downloads original. |
| `Missing required provider` for `kreuzwerker/docker` | Keep that provider in `required_providers`. The `test` state still contains the old Docker resources, and Terraform cannot read the state without it. |
