resource "tls_private_key" "this" {
  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
}

resource "tls_self_signed_cert" "this" {
  private_key_pem       = tls_private_key.this.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.validity_period_hours
  early_renewal_hours   = var.early_renewal_hours
  allowed_uses          = ["cert_signing", "crl_signing", "key_encipherment", "digital_signature"]

  subject {
    common_name  = var.common_name
    organization = var.organization
  }
}
