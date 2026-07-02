terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.4.0"
    }
  }
}

provider "docker" {
  host = "ssh://${var.ssh_user}@${var.ssh_host}:22"
}

resource "docker_network" "opensearch_net" {
  name = "opensearch-network"
}

resource "docker_volume" "opensearch_data" {
  name = "opensearch-data"
}

resource "docker_image" "opensearch" {
  name         = "opensearchproject/opensearch:2.9.0"
  platform     = "linux/arm64"
  keep_locally = true
}

resource "docker_image" "opensearch-dashboards" {
  name         = "opensearchproject/opensearch-dashboards:2.9.0"
  platform     = "linux/arm64"
  keep_locally = true
}

resource "docker_image" "logstash" {
  name = "logstash:8.19.18"
  platform     = "linux/arm64/v8"
  keep_locally = true
  build {
    context    = path.module
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "opensearch" {
  image   = docker_image.opensearch.image_id
  name    = "opensearch"
  restart = "unless-stopped"

  env = [
    "discovery.type=single-node",
    #"OPENSEARCH_INITIAL_ADMIN_PASSWORD=${var.opensearch_password}",
    "OPENSEARCH_JAVA_OPTS=-Xms256m -Xmx256m",
  ]

  ports {
    internal = 9200
    external = 19200
  }

  volumes {
    volume_name    = docker_volume.opensearch_data.name
    container_path = "/usr/share/opensearch/data"
  }

  networks_advanced {
    name = docker_network.opensearch_net.name
  }
}

resource "docker_container" "opensearch-dashboards" {
  image   = docker_image.opensearch-dashboards.image_id
  name    = "opensearch-dashboards"
  restart = "unless-stopped"

  env = [
    "OPENSEARCH_HOSTS=https://opensearch:9200",
    "OPENSEARCH_USERNAME=admin",
    "OPENSEARCH_PASSWORD=${var.opensearch_password}",
    "OPENSEARCH_SSL_VERIFICATIONMODE=none",
    "OPENSEARCH_JAVA_OPTS=-Xms256m -Xmx256m",
  ]

  ports {
    internal = 5601
    external = 15601
  }

  networks_advanced {
    name = docker_network.opensearch_net.name
  }

  depends_on = [docker_container.opensearch]
}

resource "docker_container" "logstash" {
  name  = "logstash"
  image = docker_image.logstash.image_id
  must_run = true
  restart  = "unless-stopped"
  ports {
    internal = 5044
    external = 5044
  }
}