output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.this.endpoint
  sensitive = true
}

output "node_pool_name" {
  value = google_container_node_pool.workers.name
}

output "node_image_type" {
  value = google_container_node_pool.workers.node_config[0].image_type
}
