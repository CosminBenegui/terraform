terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

locals {
  env        = "test"
  tz         = "Europe/Bucharest"
  puid       = "1000"
  pgid       = "1000"
  media_root = "/home/cosmin/media"
}

# --- Networks (Network Cards / Interfaces) ---

# Rețeaua principală (Media Network)
resource "docker_network" "media" {
  name = "media-net-${local.env}"

  ipam_config {
    subnet  = "10.20.0.0/16"
    gateway = "10.20.0.1"
  }
}

# Rețeaua secundară cu tagul "internal" (Placă de rețea internă / izolată)
resource "docker_network" "lan_internal" {
  name     = "lan-internal-net-${local.env}"
  internal = true # Izolată de internet (trafic exclusiv intern între containerele din această rețea)

  ipam_config {
    subnet  = "10.30.0.0/16"
    gateway = "10.30.0.1"
  }
}

# --- Images ---

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

# Imagine Windows Server (rulează via KVM în Docker)
resource "docker_image" "windows_server" {
  name         = "dockurr/windows:latest"
  keep_locally = true
}

# --- Config Volumes ---

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

resource "docker_volume" "win_server_data" {
  name = "win-server-data-${local.env}"
}

# --- Containers ---

# Container Windows Server cu două plăci de rețea (una pe media, una pe internal)
resource "docker_container" "windows_server" {
  name       = "windows-server"
  image      = docker_image.windows_server.name
  restart    = "unless-stopped"
  privileged = true # Necesar pentru KVM / virtualizare

  env = [
    "VERSION=win2022", # Setează Windows Server 2022
    "RAM_SIZE=4G",
    "CPU_CORES=2",
    "DISK_SIZE=64G",
  ]

  # Placa de rețea 1 (Media Network)
  networks_advanced {
    name         = docker_network.media.name
    ipv4_address = "10.20.0.50"
  }

  # Placa de rețea 2 (A doua placă - cu acces intern / izolat)
  networks_advanced {
    name         = docker_network.lan_internal.name
    ipv4_address = "10.30.0.50"
  }

  volumes {
    volume_name    = docker_volume.win_server_data.name
    container_path = "/storage"
  }

  # Acces Web Viewer (VNC/Web UI) și RDP
  ports {
    internal = 8006
    external = 8006
  }
  ports {
    internal = 3389
    external = 3389
  }
}

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

# --- Outputs ---

output "urls" {
  value = {
    windows_web_ui = "http://192.168.0.120:8006"
    windows_rdp    = "192.168.0.120:3389"
    plex           = "http://192.168.0.120:32400/web"
    prowlarr       = "http://192.168.0.120:9696"
    radarr         = "http://192.168.0.120:7878"
    sonarr         = "http://192.168.0.120:8989"
    seerr          = "http://192.168.0.120:5055"
  }
}
