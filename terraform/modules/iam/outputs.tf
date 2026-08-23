output "infra_admin_email" {
  value = data.google_service_account.infra_admin.email
}

output "gke_node_sa_email" {
  value = google_service_account.gke_nodes.email
}

output "infra_admin_roles" {
  value = local.infra_admin_roles
}

output "node_roles" {
  value = local.node_roles
}
