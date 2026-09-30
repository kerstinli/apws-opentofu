variable "netdata_image_name" {
  type        = string
  description = "Name for the Netdata Docker image."
  default     = "netdata/netdata:v2.11.1"
}

variable "host_name" {
  type        = string
  description = "Display name Netdata reports for this node in its dashboard/Cloud (NETDATA_HOST_NAME)."
  default     = "raspberry-apws"
}

variable "config_volume_name" {
  type        = string
  description = "Docker volume name for Netdata configuration."
  default     = "netdata-config"
}

variable "lib_volume_name" {
  type        = string
  description = "Docker volume name for Netdata's persisted metrics database."
  default     = "netdata-lib"
}

variable "cache_volume_name" {
  type        = string
  description = "Docker volume name for Netdata's cache."
  default     = "netdata-cache"
}

variable "claim_token" {
  type        = string
  sensitive   = true
  description = "Netdata Cloud claim token, used to connect this node to a Netdata Cloud space."
  default     = ""
}

variable "claim_url" {
  type        = string
  description = "Netdata Cloud URL to claim this node against."
  default     = "https://app.netdata.cloud"
}

variable "claim_rooms" {
  type        = string
  sensitive   = true
  description = "Comma-separated list of Netdata Cloud room IDs to claim this node into."
  default     = ""
}
