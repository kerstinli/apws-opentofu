resource "tls_private_key" "this" {
  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
}

resource "tls_self_signed_cert" "this" {
  private_key_pem       = tls_private_key.this.private_key_pem
  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = var.early_renewal_hours
  allowed_uses          = var.allowed_uses
  dns_names             = var.dns_names
  ip_addresses          = var.ip_addresses

  subject {
    common_name  = var.common_name
    organization = var.organization
  }
}
