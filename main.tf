terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "docker" {}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  env        = "test"
  tz         = "Europe/Bucharest"
  puid       = "1000"
  pgid       = "1000"
  media_root = "/home/cosmin/media"
}

# --- Networks: Docker (Media Stack) & Libvirt (Windows VM) ---

resource "docker_network" "media" {
  name = "media-net-${local.env}"

  ipam_config {
    subnet  = "10.20.0.0/16"
    gateway = "10.20.0.1"
  }
}

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

# --- Docker Images ---

resource "docker_image" "plex" {
  name         = "lscr.io/linuxserver/plex:latest"
  keep_locally = true
}

resource "docker_image" "prowlarr" {
  name         = "lscr.io/linuxserver/prowlarr:latest"
  keep_locally = true
}

resource "docker_image" "radarr" {
  name         = "lscr.io/linuxserver/radarr:latest"
  keep_locally = true
}

resource "docker_image" "sonarr" {
  name         = "lscr.io/linuxserver/sonarr:latest"
  keep_locally = true
}

resource "docker_image" "seerr" {
  name         = "ghcr.io/seerr-team/seerr:latest"
  keep_locally = true
}

resource "docker_image" "qbittorrent" {
  name         = "lscr.io/linuxserver/qbittorrent:latest"
  keep_locally = true
}

# --- Volumes ---

resource "docker_volume" "plex_config" {
  name = "plex-config-${local.env}"
}

resource "docker_volume" "prowlarr_config" {
  name = "prowlarr-config-${local.env}"
}

resource "docker_volume" "radarr_config" {
  name = "radarr-config-${local.env}"
}

resource "docker_volume" "sonarr_config" {
  name = "sonarr-config-${local.env}"
}

resource "docker_volume" "seerr_config" {
  name = "seerr-config-${local.env}"
}

resource "docker_volume" "qbittorrent_config" {
  name = "qbittorrent-config-${local.env}"
}

# --- Libvirt Resources (Windows Server VM) ---

resource "libvirt_volume" "windows_os_disk" {
  name   = "windows-server-os-${local.env}.qcow2"
  pool   = libvirt_pool.default.name
  format = "qcow2"
  size   = 68719476736 # 64 GB
}

resource "libvirt_domain" "windows_server" {
  name   = "windows-server-${local.env}"
  memory = 4096
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.windows_os_disk.id
  }

  # Placa de rețea 1 (Folosește rețeaua NAT 'default' a libvirt pentru acces extern)
  network_interface {
    network_name = "default"
  }

  # Placa de rețea 2 (A doua placă - complet izolată, internă)
  network_interface {
    network_id     = libvirt_network.internal_net.id
    wait_for_lease = false
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

# --- Docker Containers (Media Stack) ---

resource "docker_container" "plex" {
  name  = "plex"
  image = docker_image.plex.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
    "VERSION=docker",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.plex_config.name
    container_path = "/config"
  }
  volumes {
    host_path      = "${local.media_root}/movies"
    container_path = "/movies"
  }
  volumes {
    host_path      = "${local.media_root}/tv"
    container_path = "/tv"
  }

  ports {
    internal = 32400
    external = 32400
  }
}

resource "docker_container" "prowlarr" {
  name  = "prowlarr"
  image = docker_image.prowlarr.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.prowlarr_config.name
    container_path = "/config"
  }

  ports {
    internal = 9696
    external = 9696
  }
}

resource "docker_container" "radarr" {
  name  = "radarr"
  image = docker_image.radarr.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.radarr_config.name
    container_path = "/config"
  }
  volumes {
    host_path      = "${local.media_root}/movies"
    container_path = "/movies"
  }
  volumes {
    host_path      = "${local.media_root}/downloads"
    container_path = "/downloads"
  }

  ports {
    internal = 7878
    external = 7878
  }
}

resource "docker_container" "sonarr" {
  name  = "sonarr"
  image = docker_image.sonarr.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.sonarr_config.name
    container_path = "/config"
  }
  volumes {
    host_path      = "${local.media_root}/tv"
    container_path = "/tv"
  }
  volumes {
    host_path      = "${local.media_root}/downloads"
    container_path = "/downloads"
  }

  ports {
    internal = 8989
    external = 8989
  }
}

resource "docker_container" "seerr" {
  name  = "seerr"
  image = docker_image.seerr.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
    "PORT=5055",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.seerr_config.name
    container_path = "/app/config"
  }

  ports {
    internal = 5055
    external = 5055
  }
}

resource "docker_container" "qbittorrent" {
  name  = "qbittorrent"
  image = docker_image.qbittorrent.name

  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
    "WEBUI_PORT=8080",
  ]

  networks_advanced {
    name = docker_network.media.name
  }

  volumes {
    volume_name    = docker_volume.qbittorrent_config.name
    container_path = "/config"
  }
  volumes {
    host_path      = "${local.media_root}/downloads"
    container_path = "/downloads"
  }

  ports {
    internal = 8080
    external = 8080
  }
}

# --- Outputs ---

output "urls" {
  value = {
    plex        = "http://192.168.0.120:32400/web"
    prowlarr    = "http://192.168.0.120:9696"
    radarr      = "http://192.168.0.120:7878"
    sonarr      = "http://192.168.0.120:8989"
    seerr       = "http://192.168.0.120:5055"
    qbittorrent = "http://192.168.0.120:8080"
  }
}

output "media_host_paths" {
  value = {
    root      = local.media_root
    movies    = "${local.media_root}/movies"
    tv        = "${local.media_root}/tv"
    downloads = "${local.media_root}/downloads"
  }
}
