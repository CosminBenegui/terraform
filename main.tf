terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "docker" {}

locals {
  env = terraform.workspace

  # Avoid port clashes between workspaces on the same VM
  http_port = local.env == "dev" ? 8081 : 8082
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "nginx" {
  name  = "terraform-nginx-${local.env}"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = local.http_port
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello-${local.env}.txt"
  content  = "Hello from Terraform workspace ${local.env}\n"
}

output "container_name" {
  value = docker_container.nginx.name
}

output "http_port" {
  value = local.http_port
}

