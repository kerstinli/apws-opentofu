output "cert_pem" {
  value       = tls_locally_signed_cert.this.cert_pem
  description = "The PEM-encoded certificate, signed by the CA"
  sensitive   = true
}

output "private_key_pem" {
  value       = tls_private_key.this.private_key_pem
  description = "The PEM-encoded private key"
  sensitive   = true
}
