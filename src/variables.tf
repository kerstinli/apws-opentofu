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

variable "web_secret_key" {
  type        = string
  sensitive   = true
  description = "Django SECRET_KEY für den web-Container"
}

variable "allowed_hosts" {
  type        = string
  description = "Kommagetrennte Liste erlaubter Hosts für Django ALLOWED_HOSTS im web-Container"
}

variable "opensearch_host" {
  type        = string
  description = "Hostname/IP, unter der der web-Container OpenSearch erreicht"
}

variable "opensearch_port" {
  type        = number
  description = "Port, unter dem der web-Container OpenSearch erreicht"
}

variable "opensearch_user" {
  type        = string
  description = "OpenSearch-Benutzername für den web-Container"
}

variable "opensearch_use_ssl" {
  type        = bool
  description = "Ob der web-Container per SSL mit OpenSearch verbindet"
}

variable "opensearch_ssl_verify" {
  type        = bool
  description = "Ob der web-Container das OpenSearch-SSL-Zertifikat verifiziert"
}

variable "web_debug" {
  type        = bool
  description = "debug django"
}