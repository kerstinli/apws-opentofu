resource "docker_container" "this" {
  container_name    = var.container_name
  container_restart = var.container_restart
}