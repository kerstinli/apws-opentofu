output "name" {
  value       = var.name
  description = "Name der eingerichteten systemd-Unit"
  depends_on  = [terraform_data.this]
}
