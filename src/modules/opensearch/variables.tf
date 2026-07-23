variable "opensearch_password" {
  type        = string
  sensitive   = true
  description = "Admin password for OpenSearch"
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
