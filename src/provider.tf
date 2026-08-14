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
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.4.0"
    }
  }
}

provider "docker" {
  host = "ssh://${var.ssh_user}@${var.ssh_host}:22"
}

provider "opensearch" {
  url      = "https://${var.ssh_host}:${var.opensearch_port_external}"
  username = "admin"
  password = var.opensearch_password
  insecure = true
}