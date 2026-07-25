variable "opensearch_password" {
  type        = string
  sensitive   = true
  description = "Admin password for OpenSearch"
}

variable "opensearch_bootstrap_password" {
  type        = string
  sensitive   = true
  default     = "Bootstrap#0000"
  description = "Only used to pass OpenSearch's startup password-strength check. Has no effect once the security index already exists (this deployment's does), so it never has to match the real admin password."
}

variable "dashboard_cert_pem" {
  type        = string
  sensitive   = true
  description = "PEM-encoded certificate for OpenSearch Dashboards TLS"
}

variable "dashboard_key_pem" {
  type        = string
  sensitive   = true
  description = "PEM-encoded private key for OpenSearch Dashboards TLS"
}

variable "network_name" {
  type        = string
  description = "Docker network name"
  default     = "opensearch-network"
}

variable "volume_name" {
  type        = string
  description = "Docker volume name for OpenSearch data"
  default     = "opensearch-data"
}

variable "opensearch_port_external" {
  type        = number
  description = "External port for OpenSearch API"
  default     = 19200
}

variable "dashboards_port_external" {
  type        = number
  description = "External port for OpenSearch Dashboards"
  default     = 15601
}
