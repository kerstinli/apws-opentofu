variable "algorithm" {
  type        = string
  description = "Key algorithm (e.g. ECDSA, RSA)"
  default     = "ECDSA"
}

variable "ecdsa_curve" {
  type        = string
  description = "ECDSA curve (only used when algorithm = ECDSA). Provider default is P224, which most TLS stacks (incl. Node.js/OpenSSL) reject, so this module defaults to the widely-supported P256 instead."
  default     = "P256"
}

variable "common_name" {
  type        = string
  description = "CA certificate common name"
}

variable "organization" {
  type        = string
  description = "CA certificate organization"
}

variable "validity_period_hours" {
  type        = number
  description = "CA certificate validity in hours"
  default     = 87600 # 10 Jahre
}

variable "early_renewal_hours" {
  type        = number
  description = "Renew CA certificate this many hours before expiry"
  default     = 720
}
