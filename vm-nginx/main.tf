terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8"
    }
  }
}

# Runs ON the main Debian lab VM → creates a nested Ubuntu Server VM via KVM.
provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  # Give the Ubuntu guest enough RAM if you raise the Debian VM toward your ~20 GiB host.
  memory_mb = 1024
  vcpu      = 1
  disk_bytes = 10 * 1024 * 1024 * 1024 # 10 GiB
}

resource "libvirt_pool" "lab" {
  name = "terraform-lab"
  type = "dir"
  path = "/var/lib/libvirt/images/terraform-lab"
}

# Ubuntu Server cloud image (Jammy 22.04)
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-server-cloudimg-amd64.img"
  pool   = libvirt_pool.lab.name
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "nginx_disk" {
  name           = "ubuntu-nginx.qcow2"
  pool           = libvirt_pool.lab.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = local.disk_bytes
}

resource "libvirt_cloudinit_disk" "nginx_init" {
  name = "ubuntu-nginx-cloudinit.iso"
  pool = libvirt_pool.lab.name

  user_data = <<-EOF
    #cloud-config
    hostname: ubuntu-nginx
    manage_etc_hosts: true
    users:
      - name: cosmin
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: false
        plain_text_passwd: "Passw0rd!"
    ssh_pwauth: true
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
    final_message: "ubuntu-nginx ready with nginx"
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
      ens3:
        dhcp4: true
  EOF
}

resource "libvirt_domain" "ubuntu_nginx" {
  name   = "ubuntu-nginx"
  memory = local.memory_mb
  vcpu   = local.vcpu

  cloudinit = libvirt_cloudinit_disk.nginx_init.id

  disk {
    volume_id = libvirt_volume.nginx_disk.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

output "vm_name" {
  value = libvirt_domain.ubuntu_nginx.name
}

output "vm_ip" {
  value = try(libvirt_domain.ubuntu_nginx.network_interface[0].addresses[0], "pending-dhcp")
}

output "ssh_hint" {
  value = "ssh cosmin@<vm_ip>  # password Passw0rd! — change it"
}

output "nginx_hint" {
  value = "curl -I http://<vm_ip>/   # or: virsh domifaddr ubuntu-nginx"
}
