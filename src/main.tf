module "opensearch" {
  source              = "./modules/opensearch"
  opensearch_password = var.opensearch_password
  dashboard_cert_pem  = module.opensearch_dashboard_cert.cert_pem
  dashboard_key_pem   = module.opensearch_dashboard_cert.private_key_pem
}

module "opensearch_dashboard_cert" {
  source                = "./modules/tls_cert"
  ip_addresses          = ["192.168.8.168"]
  common_name           = "192.168.8.168"
  organization          = "OpenSearch Dashboard"
  validity_period_hours = 8760
  early_renewal_hours   = 720
}

module "logstash_image" {
  source           = "./modules/docker_image"
  name             = "logstash:8.19.18"
  platform         = "linux/arm64/v8"
  build_context    = path.module
  build_dockerfile = "Dockerfile"
  triggers = {
    dockerfile    = filesha256("${path.module}/Dockerfile")
    logstash_conf = filesha256("${path.module}/logstash.conf")
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
}