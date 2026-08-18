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
    "OPENSEARCH_INITIAL_ADMIN_PASSWORD=${var.opensearch_bootstrap_password}",
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

  upload {
    content = var.root_ca_cert_pem
    file    = "/usr/share/opensearch/config/root-ca.pem"
  }

  upload {
    content = var.api_cert_pem
    file    = "/usr/share/opensearch/config/esnode.pem"
  }

  upload {
    content = var.api_key_pem
    file    = "/usr/share/opensearch/config/esnode-key.pem"
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
    "SERVER_SSL_ENABLED=true",
    "SERVER_SSL_CERTIFICATE=/usr/share/opensearch-dashboards/config/certs/dashboard.pem",
    "SERVER_SSL_KEY=/usr/share/opensearch-dashboards/config/certs/dashboard-key.pem",
  ]

  upload {
    content = var.dashboard_cert_pem
    file    = "/usr/share/opensearch-dashboards/config/certs/dashboard.pem"
  }

  upload {
    content = var.dashboard_key_pem
    file    = "/usr/share/opensearch-dashboards/config/certs/dashboard-key.pem"
  }

  ports {
    internal = 5601
    external = var.dashboards_port_external
  }

  networks_advanced {
    name = docker_network.opensearch_net.name
  }

  depends_on = [docker_container.opensearch]
}

# And a full user, role and role mapping example:
resource "opensearch_role" "reader" {
  role_name   = "app_reader"
  description = "App Reader Role"

  index_permissions {
    index_patterns  = ["weather*"]
    allowed_actions = ["get", "read", "search"]
  }
}

resource "opensearch_user" "reader" {
  username = "weather-man"
  password = var.opensearch_user_pw
}

resource "opensearch_roles_mapping" "reader" {
  role_name   = opensearch_role.reader.id
  description = "App Reader Role"
  users       = [opensearch_user.reader.id]
}