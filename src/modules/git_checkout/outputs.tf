output "path" {
  value       = var.checkout_dir
  description = "Lokaler Pfad des ausgecheckten Repos"
  depends_on  = [terraform_data.this]
}
