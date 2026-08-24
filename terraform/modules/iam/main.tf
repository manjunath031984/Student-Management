data "google_service_account" "infra_admin" {
  account_id = split("@", var.infra_admin_email)[0]
  project    = var.project_id
}

resource "google_service_account" "gke_nodes" {
  project      = var.project_id
  account_id   = var.node_sa_account_id
  display_name = "GKE worker nodes for Student Management"
  description  = "Least-privilege node identity for logging, monitoring, and Artifact Registry pulls."
}

# Roles required by Terraform/Jenkins (infra-admin) for this stack.
# Owner/Editor are intentionally not granted. If apply fails on IAM,
# add only the missing role and document it in terraform/README.md.
locals {
  infra_admin_roles = [
    "roles/container.admin",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/artifactregistry.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/logging.configWriter",
    "roles/monitoring.editor",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
  ]

  node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]

  # Human operator identity used for local gcloud/kubectl (not Jenkins).
  # roles/container.clusterViewer includes container.clusters.get.
  gke_cluster_viewer_members = [
    "user:manjunathv290384@gmail.com",
  ]
}

resource "google_project_iam_member" "infra_admin" {
  for_each = toset(local.infra_admin_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_service_account.infra_admin.email}"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset(local.node_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_cluster_viewer" {
  for_each = toset(local.gke_cluster_viewer_members)

  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = each.value
}

resource "google_service_account_iam_member" "infra_admin_use_nodes" {
  service_account_id = google_service_account.gke_nodes.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_service_account.infra_admin.email}"
}
