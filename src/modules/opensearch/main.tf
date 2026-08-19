resource "docker_network" "opensearch_net" {
  name = var.network_name
}

resource "docker_volume" "opensearch_data" {
  name = var.volume_name
}

module "opensearch_image" {
  source = "../docker_image"
  name   = var.opensearch_image_name
}

module "opensearch_dashboards_image" {
  source = "../docker_image"
  name   = var.opensearch_dashboards_image_name
}

resource "docker_container" "opensearch" {
  image   = module.opensearch_image.image_id
  name    = "opensearch"
  restart = "unless-stopped"

  env = [
    "discovery.type=single-node",
    "OPENSEARCH_INITIAL_ADMIN_PASSWORD=${var.opensearch_bootstrap_password}",
    "OPENSEARCH_JAVA_OPTS=${var.opensearch_java_opts}",
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
    "OPENSEARCH_HOSTS=${var.opensearch_hosts}",
    "OPENSEARCH_USERNAME=${var.opensearch_dashboards_user}",
    "OPENSEARCH_PASSWORD=${var.opensearch_password}",
    "OPENSEARCH_SSL_VERIFICATIONMODE=full",
    "OPENSEARCH_SSL_CERTIFICATEAUTHORITIES=/usr/share/opensearch-dashboards/config/certs/root-ca.pem",
    "OPENSEARCH_JAVA_OPTS=${var.opensearch_dashboards_java_opts}",
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

  upload {
    content = var.root_ca_cert_pem
    file    = "/usr/share/opensearch-dashboards/config/certs/root-ca.pem"
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
    allowed_actions = ["get", "read", "search", "indices_monitor"]
  }
  depends_on = [docker_container.opensearch]
}

resource "opensearch_user" "reader" {
  username = "weather-man"
  password = var.opensearch_user_pw
  depends_on = [docker_container.opensearch]
}

resource "opensearch_roles_mapping" "reader" {
  role_name   = opensearch_role.reader.id
  description = "App Reader Role"
  users       = [opensearch_user.reader.id]
  depends_on = [docker_container.opensearch]
}