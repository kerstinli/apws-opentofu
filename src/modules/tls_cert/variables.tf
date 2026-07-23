variable "algorithm" {
  type        = string
  description = "Key algorithm (e.g. ECDSA, RSA)"
  default     = "ECDSA"
}

variable "dns_names" {
  type        = list(string)
  description = "DNS names / IPs for the certificate"
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
