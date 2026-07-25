resource "docker_image" "this" {
  name         = var.name
  platform     = var.platform
  keep_locally = var.keep_locally
  triggers     = var.triggers

  dynamic "build" {
    for_each = var.build_context != null ? [1] : []
    content {
      context    = var.build_context
      dockerfile = var.build_dockerfile
    }
  }
}
