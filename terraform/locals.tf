locals {
  labels = {
    project     = "student-management"
    environment = var.environment
    managed_by  = "terraform"
  }

  node_location_count = length(var.node_locations)
  node_count_per_zone = var.node_count / local.node_location_count

  apis = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

check "node_count_divisible_by_zones" {
  assert {
    condition     = var.node_count % local.node_location_count == 0
    error_message = "node_count must be evenly divisible by the number of node_locations so each zone gets the same count. For exactly 2 nodes across us-central1-a and us-central1-b, use node_count = 2."
  }
}
