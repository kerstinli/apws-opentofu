variable "ssh_host" {
  type        = string
  description = "Zielhost für die SSH-Verbindung."
}

variable "ssh_user" {
  type        = string
  description = "SSH-User auf dem Zielhost (braucht passwortlosen sudo)."
}

variable "name" {
  type        = string
  description = "Name der systemd-Unit (ohne .service)."
}

variable "description" {
  type        = string
  description = "Beschreibung der Unit."
}

variable "exec_start" {
  type        = string
  description = "Vollständiger ExecStart-Befehl."
}

variable "restart" {
  type        = string
  default     = "always"
  description = "systemd Restart-Policy."
}
