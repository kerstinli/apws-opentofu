output "opensearch_container_id" {
  value       = docker_container.opensearch.id
  description = "Container ID of the OpenSearch node"
}

output "dashboards_container_id" {
  value       = docker_container.opensearch-dashboards.id
  description = "Container ID of OpenSearch Dashboards"
}
