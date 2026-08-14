output "cert_pem" {
  value       = tls_self_signed_cert.this.cert_pem
  description = "The PEM-encoded CA certificate — import this once as a trusted root on client devices"
}

output "private_key_pem" {
  value       = tls_private_key.this.private_key_pem
  description = "The PEM-encoded CA private key — used to sign leaf certificates, never distributed to clients"
  sensitive   = true
}
