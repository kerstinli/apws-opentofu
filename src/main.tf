module "opensearch" {
  source                   = "./modules/opensearch"
  opensearch_password      = var.opensearch_password
  opensearch_user_pw       = var.opensearch_user_pw
  opensearch_port_external = var.opensearch_port_external
  dashboard_cert_pem       = module.opensearch_dashboard_cert.cert_pem
  dashboard_key_pem        = module.opensearch_dashboard_cert.private_key_pem
}

module "root_ca" {
  source       = "./modules/tls_ca"
  common_name  = "apbs Homelab Root CA"
  organization = "apbs"
}

module "opensearch_dashboard_cert" {
  source                = "./modules/tls_cert"
  ca_private_key_pem    = module.root_ca.private_key_pem
  ca_cert_pem           = module.root_ca.cert_pem
  ip_addresses          = [var.opensearch_dashboard_ip]
  common_name           = var.opensearch_dashboard_ip
  organization          = "OpenSearch Dashboard"
  validity_period_hours = 8760
  early_renewal_hours   = 720
}

module "logstash_checkout" {
  source       = "./modules/git_checkout"
  repo_url     = "https://github.com/kerstinli/apbs-logstash.git"
  ref          = var.logstash_git_ref
  checkout_dir = "${path.module}/.build/apbs-logstash"
}

module "logstash_image" {
  source           = "./modules/docker_image"
  name             = "logstash:8.19.18"
  platform         = "linux/arm64/v8"
  build_context    = "${module.logstash_checkout.path}/src"
  build_dockerfile = "Dockerfile"
  triggers = {
    git_ref = var.logstash_git_ref
  }
}

resource "docker_container" "logstash" {
  name     = "logstash"
  image    = module.logstash_image.image_id
  must_run = true
  restart  = "unless-stopped"
  ports {
    internal = 5044
    external = 5044
  }
  networks_advanced {
    name = module.opensearch.network_name
  }
}

module "web_cert" {
  source             = "./modules/tls_cert"
  ca_private_key_pem = module.root_ca.private_key_pem
  ca_cert_pem        = module.root_ca.cert_pem
  ip_addresses       = [var.opensearch_dashboard_ip]
  common_name        = var.opensearch_dashboard_ip
  organization       = "Web App"

  validity_period_hours = 8760
  early_renewal_hours   = 720
}

module "web_checkout" {
  source       = "./modules/git_checkout"
  repo_url     = "https://github.com/kerstinli/apbs-web.git"
  ref          = var.web_git_ref
  checkout_dir = "${path.module}/.build/apbs-web"
}

module "web_image" {
  source           = "./modules/docker_image"
  name             = "web:1.0"
  platform         = "linux/arm64/v8"
  build_context    = module.web_checkout.path
  build_dockerfile = "Dockerfile"
  triggers = {
    git_ref = var.web_git_ref
  }
}

resource "docker_container" "web" {
  name     = "web"
  image    = module.web_image.image_id
  must_run = true
  restart  = "unless-stopped"

  env = [
    "SECRET_KEY=${var.web_secret_key}",
    "DEBUG=${var.web_debug}",
    "ALLOWED_HOSTS=${var.allowed_hosts}",
    "OPENSEARCH_HOST=${var.opensearch_host}",
    "OPENSEARCH_PORT=${var.opensearch_port}",
    "OPENSEARCH_USER=${var.opensearch_user}",
    "OPENSEARCH_PASSWORD=${var.opensearch_user_pw}",
    "OPENSEARCH_USE_SSL=${var.opensearch_use_ssl}",
    "OPENSEARCH_SSL_VERIFY=${var.opensearch_ssl_verify}",
  ]

  command = [
    "gunicorn", "apbs.wsgi:application",
    "--bind", "0.0.0.0:8000",
    "--certfile", "/certs/web.pem",
    "--keyfile", "/certs/web-key.pem",
    "--workers", "3",
    "--threads", "2",
    "--timeout", "60",
    "--access-logfile", "-",
    "--error-logfile", "-",
  ]

  upload {
    content = module.web_cert.cert_pem
    file    = "/certs/web.pem"
  }

  upload {
    content = module.web_cert.private_key_pem
    file    = "/certs/web-key.pem"
  }

  ports {
    internal = 8000
    external = 8000
  }
}