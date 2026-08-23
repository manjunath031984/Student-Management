resource "google_compute_firewall" "allow_ssh" {
  project     = var.project_id
  name        = "gke-student-mgmt-allow-ssh"
  network     = var.network
  description = "Direct SSH (TCP/22). IAP is not used."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = [var.ssh_target_tag]
}

resource "google_compute_firewall" "allow_health_checks" {
  project     = var.project_id
  name        = "gke-student-mgmt-allow-health-checks"
  network     = var.network
  description = "GCP/GKE health checks for Gateway (ports 80 and 8080 only). PostgreSQL 5432 is not opened."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = var.health_check_ports
  }

  source_ranges = var.health_check_source_ranges
  target_tags   = [var.web_target_tag]
}
