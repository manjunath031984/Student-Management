output "infra_admin_email" {
  value = data.google_service_account.infra_admin.email
}

output "infra_admin_roles" {
  value = local.infra_admin_roles
}
