variable "opensearch_password" {
  type        = string
  sensitive   = true
  description = "Password for the OpenSearch admin user."
}

variable "ssh_host" {
  type        = string
  description = "Target host for SSH connection to the Docker daemon."
}

variable "ssh_user" {
  type        = string
  description = "SSH user on the target host (must be in the docker group)."
  default     = "docker"
}

variable "logstash_git_ref" {
  type        = string
  description = "Git tag or commit SHA in the apbs-logstash repo to build the image from."
  default     = "main"
}

variable "opensearch_dashboard_ip" {
  type        = string
  description = "IP address for the OpenSearch Dashboards TLS certificate."
}

variable "web_git_ref" {
  type        = string
  description = "Git tag or commit SHA in the apbs-web repo to build the image from."
  default     = "main"
}

variable "opensearch_user_pw" {
  type        = string
  sensitive   = true
  description = "Password for the OpenSearch user 'weather-man'."
}

variable "opensearch_port_external" {
  type        = number
  description = "External port for the OpenSearch API."
  default     = 19200
}

variable "web_secret_key" {
  type        = string
  sensitive   = true
  description = "Django SECRET_KEY for the web container."
}

variable "allowed_hosts" {
  type        = string
  description = "Comma-separated list of allowed hosts for Django ALLOWED_HOSTS in the web container."
  default     = "localhost,127.0.0.1"
}

variable "opensearch_host" {
  type        = string
  description = "Hostname/IP where the web container can reach OpenSearch."
  default     = "opensearch"
}

variable "opensearch_port" {
  type        = number
  description = "Port where the web container can reach OpenSearch."
  default     = 9200
}

variable "opensearch_user" {
  type        = string
  description = "OpenSearch username for the web container."
  default     = "admin"
}

variable "opensearch_admin_user" {
  type        = string
  description = "OpenSearch admin username used by the opensearch provider itself to provision roles/users. Kept separate from opensearch_user (the web container's runtime user) so lowering the web app's privileges never breaks Terraform's own provisioning."
  default     = "admin"
}

variable "opensearch_use_ssl" {
  type        = bool
  description = "Whether the web container connects to OpenSearch via SSL."
  default     = true
}

variable "opensearch_ssl_verify" {
  type        = bool
  description = "Whether the web container verifies the OpenSearch SSL certificate."
  default     = true
}

variable "web_debug" {
  type        = bool
  description = "Enable Django debug mode."
  default     = false
}

variable "logstash_image_name" {
  type        = string
  description = "Name for the Logstash Docker image."
  default     = "logstash:8.19.18"
}

variable "web_image_name" {
  type        = string
  description = "Name for the web Docker image."
  default     = "web:1.0"
}

variable "docker_platform" {
  type        = string
  description = "Target platform for Docker images."
  default     = "linux/arm64/v8"
}