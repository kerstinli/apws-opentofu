output "container_id" {
  value       = docker_container.netdata.id
  description = "Container ID of the Netdata agent"
}
