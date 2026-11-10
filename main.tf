terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

# Kept so this apply can destroy the Windows VM still recorded in state.
provider "libvirt" {
  uri = "qemu:///system"
}

# Ansible configures the host after every apply. A new timestamp forces the run.
resource "terraform_data" "ansible_configure" {
  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    command     = "stdbuf -oL -eL ansible-playbook site.yml"
  }
}
