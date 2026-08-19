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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "docker" {
  host = "ssh://${var.ssh_user}@${var.ssh_host}:22"
}

provider "opensearch" {
  url         = "https://${var.ssh_host}:${var.opensearch_port_external}"
  username    = var.opensearch_admin_user
  password    = var.opensearch_password
  cacert_file = local_file.root_ca_cert.filename
}