terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  env = "test"
  # Staged into the libvirt pool by CI (QEMU cannot read files under /home/cosmin).
  windows_iso_path = "/var/lib/libvirt/images/SERVER_EVAL_x64FRE_en-us.iso"
}

# --- Libvirt network (Windows VM) ---

resource "libvirt_network" "internal_net" {
  name      = "win-internal-${local.env}"
  mode      = "none"
  addresses = ["10.30.0.0/16"]
}

# --- Libvirt Storage Pool ---
resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

# --- Libvirt Resources (Windows Server VM) ---

resource "libvirt_volume" "windows_os_disk" {
  name   = "windows-srv-disk-${local.env}.qcow2"
  pool   = libvirt_pool.default.name
  format = "qcow2"
  size   = 268435456000 # 250 GiB

  # Provider often leaves the volume as root:root; QEMU runs as libvirt-qemu.
  provisioner "local-exec" {
    command = "sudo chown libvirt-qemu:kvm '${self.id}' && sudo chmod 660 '${self.id}' && ls -la '${self.id}'"
  }
}

resource "libvirt_domain" "windows_server" {
  # Include env so renames don't collide with orphan domains left outside state.
  name   = "windows-srv-${local.env}"
  memory = 4096
  vcpu   = 2

  # Empty OS disk first; ISO as file-backed CDROM (provider treats .iso as cdrom).
  disk {
    volume_id = libvirt_volume.windows_os_disk.id
  }

  disk {
    file = local.windows_iso_path
  }

  # Empty hd → fall through to installer ISO (same idea as virt-manager).
  boot_device {
    dev = ["hd", "cdrom"]
  }

  network_interface {
    network_name = "default"
  }

  network_interface {
    network_id     = libvirt_network.internal_net.id
    wait_for_lease = false
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "0.0.0.0" # LAN access (e.g. RealVNC on iOS → 192.168.0.120)
    autoport       = true
  }

  # Default disk bus is virtio; Windows Setup won't see it without virtio drivers.
  # Force SATA for the OS disk so the installer can target the qcow2 volume.
  xml {
    xslt = <<-XSLT
      <?xml version="1.0" ?>
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output omit-xml-declaration="yes" indent="yes"/>
        <xsl:template match="node()|@*">
          <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
          </xsl:copy>
        </xsl:template>
        <xsl:template match="/domain/devices/disk[@device='disk']/target/@bus">
          <xsl:attribute name="bus">sata</xsl:attribute>
        </xsl:template>
        <xsl:template match="/domain/devices/disk[@device='disk']/target/@dev">
          <xsl:attribute name="dev">sda</xsl:attribute>
        </xsl:template>
        <xsl:template match="/domain/devices/disk[@device='disk']/address"/>
      </xsl:stylesheet>
    XSLT
  }
}

# Runs after every apply, once the VM and disk exist. Ansible configures the host,
# Traefik, Authentik, and the media apps. A new timestamp forces this to run every apply.
resource "terraform_data" "ansible_configure" {
  depends_on = [libvirt_domain.windows_server]

  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    command     = "stdbuf -oL -eL ansible-playbook site.yml"
  }
}

output "windows_vnc" {
  value = "Connect RealVNC to 192.168.0.120 — port from: virsh -c qemu:///system vncdisplay windows-srv-test"
}
