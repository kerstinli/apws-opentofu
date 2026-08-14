variable "opensearch_password" {
  type      = string
  sensitive = true
}

variable "ssh_host" {
  type        = string
  description = "Zielhost für SSH-Verbindung zum Docker-Daemon"
}

variable "ssh_user" {
  type        = string
  description = "SSH-User auf dem Zielhost (muss in der docker-Gruppe sein)"
}

variable "logstash_git_ref" {
  type        = string
  description = "Git-Tag oder Commit-SHA im apbs-logstash-Repo, aus dem das Image gebaut wird"
}

variable "opensearch_dashboard_ip" {
  type        = string
  description = "IP-Adresse, für die das TLS-Zertifikat des OpenSearch Dashboards ausgestellt wird"
}

variable "web_git_ref" {
  type        = string
  description = "Git-Tag oder Commit-SHA im apbs-web-Repo, aus dem das Image gebaut wird"
}

variable "opensearch_user_pw" {
  type        = string
  sensitive   = true
  description = "password for OpenSearch User weather-man"
}

variable "opensearch_port_external" {
  type        = number
  description = "External port for OpenSearch API"
  default     = 19200
}