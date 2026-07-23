output "image_id" {
  value       = docker_image.this.image_id
  description = "The ID of the pulled Docker image"
}
