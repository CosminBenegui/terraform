# Ubuntu Server VM + nginx (nested on the Debian lab)

```text
Hypervisor host (~20 GiB RAM total — give Debian enough, e.g. 8–12 GiB)
  └── Debian lab VM (Docker media: plex, radarr, …)   ← ../main.tf
        └── KVM nested VM: Ubuntu Server "ubuntu-nginx" + nginx  ← this folder
```

Docker apps stay on Debian. This stack only creates the **Ubuntu** guest.

## 0) Prefer: give Debian more RAM

In your hypervisor, raise the Debian VM memory (e.g. 8 GiB+). Nested Ubuntu is set to **1 GiB** here.

## 1) One-time on Debian

```bash
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst genisoimage
sudo usermod -aG libvirt,kvm cosmin
# re-login
sudo systemctl enable --now libvirtd
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default
```

## 2) Apply (on Debian, not via media Actions)

```bash
cd vm-nginx
terraform init
terraform apply
virsh list --all
virsh domifaddr ubuntu-nginx
curl -I http://<ip>/
ssh cosmin@<ip>   # Passw0rd!
```

## 3) Destroy

```bash
terraform destroy
```

## If you meant a *sibling* Ubuntu VM next to Debian

That is created in **Proxmox / VMware / Hyper-V**, not inside Debian. Say which hypervisor you use and we can switch providers. This folder is the **nested** approach (Terraform + libvirt on Debian).
