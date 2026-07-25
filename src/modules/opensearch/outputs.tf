output "opensearch_container_id" {
  value       = docker_container.opensearch.id
  description = "Container ID of the OpenSearch node"
}

output "dashboards_container_id" {
  value       = docker_container.opensearch-dashboards.id
  description = "Container ID of OpenSearch Dashboards"
}

output "network_name" {
  value       = docker_network.opensearch_net.name
  description = "Name of the Docker network OpenSearch/Dashboards run in — join this to reach them by container name"
}
