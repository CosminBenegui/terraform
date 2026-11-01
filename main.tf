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
  env  = terraform.workspace
  tz   = "Europe/Bucharest"
  puid = "1000"
  pgid = "1000"

  # Host paths on the VM (shared so *arr + Plex see the same files)
  media_root = "/home/cosmin/media"
}

# Shared network — plex, prowlarr, radarr, sonarr, seerr (Overseerr-compatible)
resource "docker_network" "media" {
  name = "media-net-${local.env}"

  ipam_config {
    subnet = local.env == "dev" ? "10.10.0.0/16" : "10.20.0.0/16"
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

# --- Config volumes (per app) ---

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

# --- Apps ---

resource "docker_container" "plex" {
  name  = "plex"
  image = docker_image.plex.image_id

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
  image = docker_image.prowlarr.image_id

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
  image = docker_image.radarr.image_id

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
  image = docker_image.sonarr.image_id

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
  image = docker_image.seerr.image_id

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

output "urls" {
  value = {
    plex     = "http://192.168.0.150:32400/web"
    prowlarr = "http://192.168.0.150:9696"
    radarr   = "http://192.168.0.150:7878"
    sonarr   = "http://192.168.0.150:8989"
    seerr    = "http://192.168.0.150:5055"
  }
}

output "internal_links" {
  value = {
    radarr_from_prowlarr = "http://radarr:7878"
    sonarr_from_prowlarr = "http://sonarr:8989"
    plex_from_seerr      = "http://plex:32400"
    radarr_from_seerr    = "http://radarr:7878"
    sonarr_from_seerr    = "http://sonarr:8989"
    movies_path_in_apps  = "/movies"
    tv_path_in_apps      = "/tv"
    downloads_path       = "/downloads"
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
