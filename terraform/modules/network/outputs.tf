output "network_name" {
  value = google_compute_network.vpc.name
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnet_name" {
  value = google_compute_subnetwork.gke.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.gke.self_link
}

output "subnet_cidr" {
  value = google_compute_subnetwork.gke.ip_cidr_range
}

output "pods_cidr" {
  value = var.pods_cidr
}

output "services_cidr" {
  value = var.services_cidr
}

output "proxy_only_cidr" {
  value = google_compute_subnetwork.proxy_only.ip_cidr_range
}
