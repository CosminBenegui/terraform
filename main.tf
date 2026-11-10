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
  env                = "test"
  tz                 = "Europe/Bucharest"
  puid               = "1000"
  pgid               = "1000"
  media_root         = "/home/cosmin/media"
  windows_iso_source = "/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso"
  windows_iso_path   = "/var/lib/libvirt/images/SERVER_EVAL_x64FRE_en-us.iso"
  authentik_image    = "ghcr.io/goauthentik/server:2026.8.5"
  secrets_path       = "/home/cosmin/.config/lab/secrets.env"

  secret_map = {
    for line in split("\n", file(local.secrets_path)) :
    split("=", trimspace(line))[0] => join("=", slice(split("=", trimspace(line)), 1, length(split("=", trimspace(line)))))
    if length(trimspace(line)) > 0 && substr(trimspace(line), 0, 1) != "#" && length(split("=", trimspace(line))) > 1
  }
}

# site.yml writes config files and host packages before any container or VM exists.
resource "terraform_data" "ansible_prepare" {
  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    command     = "stdbuf -oL -eL ansible-playbook site.yml"
  }
}

# --- Docker network and images ---

resource "docker_network" "media" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "media-net-${local.env}"

  ipam_config {
    subnet  = "10.20.0.0/16"
    gateway = "10.20.0.1"
  }
}

resource "docker_image" "plex" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "lscr.io/linuxserver/plex:latest"
  keep_locally = true
}

resource "docker_image" "prowlarr" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "lscr.io/linuxserver/prowlarr:latest"
  keep_locally = true
}

resource "docker_image" "radarr" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "lscr.io/linuxserver/radarr:latest"
  keep_locally = true
}

resource "docker_image" "sonarr" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "lscr.io/linuxserver/sonarr:latest"
  keep_locally = true
}

resource "docker_image" "seerr" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "ghcr.io/seerr-team/seerr:latest"
  keep_locally = true
}

resource "docker_image" "qbittorrent" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "lscr.io/linuxserver/qbittorrent:latest"
  keep_locally = true
}

resource "docker_image" "glances" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "nicolargo/glances:latest"
  keep_locally = true
}

resource "docker_image" "traefik" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "traefik:latest"
  keep_locally = true
}

resource "docker_image" "postgres" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "docker.io/library/postgres:latest"
  keep_locally = true
}

resource "docker_image" "redis" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "docker.io/library/redis:latest"
  keep_locally = true
}

resource "docker_image" "authentik" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = local.authentik_image
  keep_locally = true
}

resource "docker_image" "grafana" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_image" "loki" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "grafana/loki:latest"
  keep_locally = true
}

resource "docker_image" "prometheus" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_image" "alloy" {
  depends_on   = [terraform_data.ansible_prepare]
  name         = "grafana/alloy:latest"
  keep_locally = true
}

# --- Volumes ---

resource "docker_volume" "plex_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "plex-config-${local.env}"
}

resource "docker_volume" "prowlarr_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "prowlarr-config-${local.env}"
}

resource "docker_volume" "radarr_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "radarr-config-${local.env}"
}

resource "docker_volume" "sonarr_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "sonarr-config-${local.env}"
}

resource "docker_volume" "seerr_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "seerr-config-${local.env}"
}

resource "docker_volume" "qbittorrent_config" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "qbittorrent-config-${local.env}"
}

resource "docker_volume" "authentik_db" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "authentik-db"
}

resource "docker_volume" "grafana_data" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "grafana-data"
}

resource "docker_volume" "loki_data" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "loki-data"
}

resource "docker_volume" "prometheus_data" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "prometheus-data"
}

resource "docker_volume" "alloy_data" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "alloy-data"
}

# --- Media containers ---

resource "docker_container" "plex" {
  name    = "plex"
  image   = docker_image.plex.image_id
  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
    "VERSION=docker",
  ]
  ports {
    internal = 32400
    external = 32400
  }
  mounts {
    type   = "volume"
    source = docker_volume.plex_config.name
    target = "/config"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/movies"
    target = "/movies"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/tv"
    target = "/tv"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "prowlarr" {
  name    = "prowlarr"
  image   = docker_image.prowlarr.image_id
  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]
  ports {
    internal = 9696
    external = 9696
  }
  mounts {
    type   = "volume"
    source = docker_volume.prowlarr_config.name
    target = "/config"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "radarr" {
  name    = "radarr"
  image   = docker_image.radarr.image_id
  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]
  ports {
    internal = 7878
    external = 7878
  }
  mounts {
    type   = "volume"
    source = docker_volume.radarr_config.name
    target = "/config"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/movies"
    target = "/movies"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/downloads"
    target = "/downloads"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "sonarr" {
  name    = "sonarr"
  image   = docker_image.sonarr.image_id
  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
  ]
  ports {
    internal = 8989
    external = 8989
  }
  mounts {
    type   = "volume"
    source = docker_volume.sonarr_config.name
    target = "/config"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/tv"
    target = "/tv"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/downloads"
    target = "/downloads"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "seerr" {
  name    = "seerr"
  image   = docker_image.seerr.image_id
  restart = "unless-stopped"
  env = [
    "TZ=${local.tz}",
    "PORT=5055",
  ]
  ports {
    internal = 5055
    external = 5055
  }
  mounts {
    type   = "volume"
    source = docker_volume.seerr_config.name
    target = "/app/config"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "qbittorrent" {
  name    = "qbittorrent"
  image   = docker_image.qbittorrent.image_id
  restart = "unless-stopped"
  env = [
    "PUID=${local.puid}",
    "PGID=${local.pgid}",
    "TZ=${local.tz}",
    "WEBUI_PORT=8080",
  ]
  ports {
    internal = 8080
    external = 8080
  }
  ports {
    internal = 6881
    external = 6881
  }
  ports {
    internal = 6881
    external = 6881
    protocol = "udp"
  }
  mounts {
    type   = "volume"
    source = docker_volume.qbittorrent_config.name
    target = "/config"
  }
  mounts {
    type   = "bind"
    source = "${local.media_root}/downloads"
    target = "/downloads"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

# --- Glances, Traefik, Authentik, Grafana ---

resource "docker_container" "glances" {
  name         = "glances"
  image        = docker_image.glances.image_id
  restart      = "unless-stopped"
  network_mode = "host"
  pid_mode     = "host"
  env = [
    "TZ=${local.tz}",
    "GLANCES_OPT=-C /glances/conf/glances.conf -w",
  ]
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/monitor/glances.conf"
    target    = "/glances/conf/glances.conf"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/var/run/docker.sock"
    target    = "/var/run/docker.sock"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/etc/os-release"
    target    = "/etc/os-release"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/"
    target    = "/rootfs"
    read_only = true
  }
  tmpfs = {
    "/tmp" = ""
  }
}

resource "docker_container" "traefik" {
  name    = "traefik"
  image   = docker_image.traefik.image_id
  restart = "unless-stopped"
  command = ["--configFile=/etc/traefik/traefik.yml"]
  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/traefik"
    target    = "/etc/traefik"
    read_only = true
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "authentik_postgresql" {
  name    = "authentik-postgresql"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"
  env = [
    "POSTGRES_PASSWORD=${local.secret_map["AUTHENTIK_PG_PASS"]}",
    "POSTGRES_USER=authentik",
    "POSTGRES_DB=authentik",
  ]
  mounts {
    type   = "volume"
    source = docker_volume.authentik_db.name
    target = "/var/lib/postgresql"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "authentik_redis" {
  name    = "authentik-redis"
  image   = docker_image.redis.image_id
  restart = "unless-stopped"
  command = ["--save", "60", "1", "--loglevel", "warning"]
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "authentik" {
  name    = "authentik"
  image   = docker_image.authentik.image_id
  restart = "unless-stopped"
  command = ["server"]
  env = [
    "AUTHENTIK_SECRET_KEY=${local.secret_map["AUTHENTIK_SECRET_KEY"]}",
    "AUTHENTIK_HOST=https://auth.lab.home",
    "AUTHENTIK_REDIS__HOST=authentik-redis",
    "AUTHENTIK_POSTGRESQL__HOST=authentik-postgresql",
    "AUTHENTIK_POSTGRESQL__USER=authentik",
    "AUTHENTIK_POSTGRESQL__NAME=authentik",
    "AUTHENTIK_POSTGRESQL__PASSWORD=${local.secret_map["AUTHENTIK_PG_PASS"]}",
    "AUTHENTIK_BOOTSTRAP_PASSWORD=${local.secret_map["AUTHENTIK_BOOTSTRAP_PASSWORD"]}",
    "AUTHENTIK_BOOTSTRAP_TOKEN=${local.secret_map["AUTHENTIK_BOOTSTRAP_TOKEN"]}",
    "AUTHENTIK_ERROR_REPORTING__ENABLED=false",
  ]
  ports {
    internal = 9000
    external = 9000
  }
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/authentik/media-apps.yaml"
    target    = "/blueprints/custom/media-apps.yaml"
    read_only = true
  }
  networks_advanced {
    name = docker_network.media.name
  }
  depends_on = [
    docker_container.authentik_postgresql,
    docker_container.authentik_redis,
  ]
}

resource "docker_container" "authentik_worker" {
  name    = "authentik-worker"
  image   = docker_image.authentik.image_id
  restart = "unless-stopped"
  command = ["worker"]
  env = [
    "AUTHENTIK_SECRET_KEY=${local.secret_map["AUTHENTIK_SECRET_KEY"]}",
    "AUTHENTIK_HOST=https://auth.lab.home",
    "AUTHENTIK_REDIS__HOST=authentik-redis",
    "AUTHENTIK_POSTGRESQL__HOST=authentik-postgresql",
    "AUTHENTIK_POSTGRESQL__USER=authentik",
    "AUTHENTIK_POSTGRESQL__NAME=authentik",
    "AUTHENTIK_POSTGRESQL__PASSWORD=${local.secret_map["AUTHENTIK_PG_PASS"]}",
    "AUTHENTIK_ERROR_REPORTING__ENABLED=false",
  ]
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/authentik/media-apps.yaml"
    target    = "/blueprints/custom/media-apps.yaml"
    read_only = true
  }
  networks_advanced {
    name = docker_network.media.name
  }
  depends_on = [
    docker_container.authentik_postgresql,
    docker_container.authentik_redis,
  ]
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"
  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=1234",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_AUTH_DISABLE_LOGIN_FORM=true",
    "GF_AUTH_PROXY_ENABLED=true",
    "GF_AUTH_PROXY_HEADER_NAME=X-authentik-username",
    "GF_AUTH_PROXY_AUTO_SIGN_UP=true",
    "GF_SERVER_ROOT_URL=https://grafana.lab.home",
  ]
  mounts {
    type   = "volume"
    source = docker_volume.grafana_data.name
    target = "/var/lib/grafana"
  }
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/grafana/provisioning"
    target    = "/etc/grafana/provisioning"
    read_only = true
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "loki" {
  name    = "loki"
  image   = docker_image.loki.image_id
  restart = "unless-stopped"
  command = ["-config.file=/etc/loki/loki.yml"]
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/grafana/loki.yml"
    target    = "/etc/loki/loki.yml"
    read_only = true
  }
  mounts {
    type   = "volume"
    source = docker_volume.loki_data.name
    target = "/loki"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.enable-remote-write-receiver",
  ]
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/grafana/prometheus.yml"
    target    = "/etc/prometheus/prometheus.yml"
    read_only = true
  }
  mounts {
    type   = "volume"
    source = docker_volume.prometheus_data.name
    target = "/prometheus"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

resource "docker_container" "alloy" {
  name    = "alloy"
  image   = docker_image.alloy.image_id
  restart = "unless-stopped"
  command = [
    "run",
    "--server.http.listen-addr=127.0.0.1:12345",
    "--storage.path=/var/lib/alloy/data",
    "/etc/alloy/config.alloy",
  ]
  mounts {
    type      = "bind"
    source    = "/var/lib/lab/compose/grafana/config.alloy"
    target    = "/etc/alloy/config.alloy"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/var/run/docker.sock"
    target    = "/var/run/docker.sock"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/proc"
    target    = "/host/proc"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/sys"
    target    = "/host/sys"
    read_only = true
  }
  mounts {
    type      = "bind"
    source    = "/"
    target    = "/host/root"
    read_only = true
  }
  mounts {
    type   = "volume"
    source = docker_volume.alloy_data.name
    target = "/var/lib/alloy"
  }
  networks_advanced {
    name = docker_network.media.name
  }
}

# --- Windows Server ---

resource "libvirt_network" "internal_net" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "win-internal-${local.env}"
  mode       = "none"
  addresses  = ["10.30.0.0/16"]
}

resource "libvirt_pool" "default" {
  depends_on = [terraform_data.ansible_prepare]
  name       = "default"
  type       = "dir"
  path       = "/var/lib/libvirt/images"

  # The pool build creates the directory. Copy the ISO after that, and never delete Downloads.
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

# App links need the containers to be up. Config files were written by ansible_prepare.
resource "terraform_data" "ansible_configure" {
  depends_on = [
    docker_container.plex,
    docker_container.prowlarr,
    docker_container.radarr,
    docker_container.sonarr,
    docker_container.seerr,
    docker_container.qbittorrent,
    docker_container.glances,
    docker_container.traefik,
    docker_container.authentik,
    docker_container.authentik_worker,
    docker_container.grafana,
    docker_container.loki,
    docker_container.prometheus,
    docker_container.alloy,
    libvirt_domain.windows_server,
  ]

  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    command     = "stdbuf -oL -eL ansible-playbook site-configure.yml"
  }
}

output "apps" {
  value = {
    radarr     = "https://radarr.lab.home"
    sonarr     = "https://sonarr.lab.home"
    prowlarr   = "https://prowlarr.lab.home"
    seerr      = "https://seerr.lab.home"
    qbittorrent = "https://qbit.lab.home"
    glances    = "https://monitor.lab.home"
    grafana    = "https://grafana.lab.home"
    authentik  = "https://auth.lab.home"
    plex       = "http://192.168.0.120:32400/web"
  }
}

output "windows_vnc" {
  value = "Connect RealVNC to 192.168.0.120 — port from: virsh -c qemu:///system vncdisplay windows-srv-test"
}
