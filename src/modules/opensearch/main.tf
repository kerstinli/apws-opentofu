resource "docker_network" "opensearch_net" {
  name = var.network_name
}

resource "docker_volume" "opensearch_data" {
  name = var.volume_name
}

module "opensearch_image" {
  source = "../docker_image"
  name   = "opensearchproject/opensearch:3.7.0"
}

module "opensearch_dashboards_image" {
  source = "../docker_image"
  name   = "opensearchproject/opensearch-dashboards:3.7.0"
}

resource "docker_container" "opensearch" {
  image   = module.opensearch_image.image_id
  name    = "opensearch"
  restart = "unless-stopped"

  env = [
    "discovery.type=single-node",
    "OPENSEARCH_INITIAL_ADMIN_PASSWORD=${var.opensearch_password}",
    "OPENSEARCH_JAVA_OPTS=-Xms256m -Xmx256m",
  ]

  ports {
    internal = 9200
    external = var.opensearch_port_external
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
  image   = module.opensearch_dashboards_image.image_id
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
    external = var.dashboards_port_external
  }

  networks_advanced {
    name = docker_network.opensearch_net.name
  }

  depends_on = [docker_container.opensearch]
}
