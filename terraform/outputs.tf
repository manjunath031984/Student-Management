output "project_id" {
  value = var.project_id
}

output "network_name" {
  value = module.network.network_name
}

output "subnet_name" {
  value = module.network.subnet_name
}

output "subnet_cidr" {
  value = module.network.subnet_cidr
}

output "pods_secondary_range" {
  value = module.network.pods_cidr
}

output "services_secondary_range" {
  value = module.network.services_cidr
}

output "proxy_only_subnet_cidr" {
  value = module.network.proxy_only_cidr
}

output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_region" {
  value = var.region
}

output "cluster_zones" {
  value = var.node_locations
}

output "node_pool_name" {
  value = module.gke.node_pool_name
}

output "node_count" {
  value = var.node_count
}

output "node_count_per_zone" {
  value = local.node_count_per_zone
}

output "node_image_type" {
  value = var.node_image_type
}

output "artifact_registry_repository" {
  value = module.artifact_registry.repository_id
}

output "artifact_registry_location" {
  value = var.region
}
