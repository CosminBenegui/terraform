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
  env                = "test"
  windows_iso_source = "/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso"
  windows_iso_path   = "/var/lib/libvirt/images/SERVER_EVAL_x64FRE_en-us.iso"
}

# Isolated network for the Windows Server. It has no uplink.
resource "libvirt_network" "internal_net" {
  name      = "win-internal-${local.env}"
  mode      = "none"
  addresses = ["10.30.0.0/16"]
}

# Storage pool. The provisioner copies the installer into the pool.
# The original ISO in Downloads is never deleted.
resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"

  provisioner "local-exec" {
    command = "sudo test -f '${local.windows_iso_source}' && sudo cp '${local.windows_iso_source}' '${local.windows_iso_path}' && sudo chown libvirt-qemu:kvm '${local.windows_iso_path}' && sudo chmod 644 '${local.windows_iso_path}'"
  }
}

resource "libvirt_volume" "windows_os_disk" {
  name   = "windows-srv-disk-${local.env}.qcow2"
  pool   = libvirt_pool.default.name
  format = "qcow2"
  size   = 268435456000 # 250 GiB

  provisioner "local-exec" {
    command = "sudo chown libvirt-qemu:kvm '${self.id}' && sudo chmod 660 '${self.id}' && ls -la '${self.id}'"
  }
}

resource "libvirt_domain" "windows_server" {
  depends_on = [libvirt_pool.default]
  name       = "windows-srv-${local.env}"
  memory     = 4096
  vcpu       = 2

  disk {
    volume_id = libvirt_volume.windows_os_disk.id
  }

  disk {
    file = local.windows_iso_path
  }

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
    listen_address = "0.0.0.0"
    autoport       = true
  }

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

output "windows_vnc" {
  value = "Connect RealVNC to 192.168.0.120. The port comes from: virsh -c qemu:///system vncdisplay windows-srv-test"
}
