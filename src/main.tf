module "opensearch" {
  source              = "./modules/opensearch"
  opensearch_password = var.opensearch_password
}

module "opensearch_dashboard_cert" {
  source       = "./modules/tls_cert"
  dns_names    = ["192.168.8.168:15601"]
  common_name  = "192.168.8.168"
  organization = "OpenSearch Dashboard"
}



module "logstash_image" {
  source           = "./modules/docker_image"
  name             = "logstash:8.19.18"
  platform         = "linux/arm64/v8"
  build_context    = path.module
  build_dockerfile = "Dockerfile"
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
