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
