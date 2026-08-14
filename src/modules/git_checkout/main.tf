resource "terraform_data" "this" {
  triggers_replace = [var.repo_url, var.ref]

  provisioner "local-exec" {
    command = "rm -rf '${var.checkout_dir}' && git clone --quiet '${var.repo_url}' '${var.checkout_dir}' && git -C '${var.checkout_dir}' checkout --quiet '${var.ref}'"
  }
}
