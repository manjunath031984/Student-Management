data "google_service_account" "infra_admin" {
  account_id = split("@", var.infra_admin_email)[0]
  project    = var.project_id
}

# Roles required by Terraform/Jenkins (infra-admin) for this stack,
# plus node-identity roles needed because GKE workers use this same account.
# Owner/Editor are intentionally not granted.
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
    "roles/logging.logWriter",
    "roles/monitoring.editor",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
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

resource "google_project_iam_member" "gke_cluster_viewer" {
  for_each = toset(local.gke_cluster_viewer_members)

  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = each.value
}
