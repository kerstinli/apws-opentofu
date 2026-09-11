resource "terraform_data" "this" {
  triggers_replace = [var.exec_start, var.restart]

  connection {
    type  = "ssh"
    host  = var.ssh_host
    user  = var.ssh_user
    agent = true
  }

  provisioner "file" {
    content = templatefile("${path.module}/unit.tftpl", {
      description = var.description
      exec_start  = var.exec_start
      restart     = var.restart
    })
    destination = "/tmp/${var.name}.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/${var.name}.service /etc/systemd/system/${var.name}.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now ${var.name}",
    ]
  }
}
