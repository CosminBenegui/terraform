terraform {
  required_version = ">= 1.5.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-server-cloudimg-amd64.img"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "nginx_disk" {
  name           = "ubuntu-nginx.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 10 * 1024 * 1024 * 1024
}

resource "libvirt_cloudinit_disk" "nginx_init" {
  name = "ubuntu-nginx-cloudinit.iso"
  pool = "default"

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
  memory = "1024"
  vcpu   = 1

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

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

output "vm_name" {
  value = libvirt_domain.ubuntu_nginx.name
}

output "vm_ip" {
  value = try(libvirt_domain.ubuntu_nginx.network_interface[0].addresses[0], "check virsh")
}
