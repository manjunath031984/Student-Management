output "enabled_apis" {
  value = [for s in google_project_service.this : s.service]
}
