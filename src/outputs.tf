output "root_ca_cert_pem" {
  value       = module.root_ca.cert_pem
  description = "PEM-encoded Root-CA-Zertifikat — einmalig als vertrauenswürdige Root in Browser/OS importieren (tofu output -raw root_ca_cert_pem > ca.pem)"
}
