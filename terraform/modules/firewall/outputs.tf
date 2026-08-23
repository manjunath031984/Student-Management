output "ssh_firewall_name" {
  value = google_compute_firewall.allow_ssh.name
}

output "health_check_firewall_name" {
  value = google_compute_firewall.allow_health_checks.name
}
