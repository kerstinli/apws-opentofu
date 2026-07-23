terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "docker" {
  host = "ssh://${var.ssh_user}@${var.ssh_host}:22"
}
