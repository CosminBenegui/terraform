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
  env       = terraform.workspace
  http_port = local.env == "dev" ? 8081 : 8082
}

# Private network (course "VNet" + address_space → Docker IPAM subnet).
resource "docker_network" "main" {
  name = "vnet-main-${local.env}"

  ipam_config {
    subnet = "10.0.0.0/16"
  }
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Nginx container attached to docker_network.main
resource "docker_container" "nginx" {
  name  = "nginx-${local.env}"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.main.name
  }

  ports {
    internal = 80
    external = local.http_port
  }
}

output "vnet_name" {
  value = docker_network.main.name
}

output "nginx_name" {
  value = docker_container.nginx.name
}

output "http_port" {
  value = local.http_port
}
