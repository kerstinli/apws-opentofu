variable "algorithm" {
  type        = string
  description = "Key algorithm (e.g. ECDSA, RSA)"
  default     = "ECDSA"
}

variable "ecdsa_curve" {
  type        = string
  description = "ECDSA curve (only used when algorithm = ECDSA). Provider default is P224, which most TLS stacks (incl. Node.js/OpenSSL) reject for server certs, so this module defaults to the widely-supported P256 instead."
  default     = "P256"
}

variable "dns_names" {
  type        = list(string)
  description = "DNS names for the certificate"
  default     = []
}

variable "ip_addresses" {
  type        = list(string)
  description = "IP addresses for the certificate (SAN iPAddress entries)"
  default     = []
}

variable "common_name" {
  type        = string
  description = "Certificate common name"
}

variable "organization" {
  type        = string
  description = "Certificate organization"
}

variable "validity_period_hours" {
  type        = number
  description = "Certificate validity in hours"
  default     = 12
}

variable "early_renewal_hours" {
  type        = number
  description = "Renew certificate this many hours before expiry"
  default     = 3
}

variable "allowed_uses" {
  type        = list(string)
  description = "Allowed certificate uses"
  default     = ["key_encipherment", "digital_signature", "server_auth"]
}
