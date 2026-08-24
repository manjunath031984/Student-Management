module "project_services" {
  source     = "./modules/project-services"
  project_id = var.project_id
  apis       = local.apis
}

module "iam" {
  source            = "./modules/iam"
  project_id        = var.project_id
  infra_admin_email = var.infra_admin_email
  labels            = local.labels

  depends_on = [module.project_services]
}

module "network" {
  source                 = "./modules/network"
  project_id             = var.project_id
  region                 = var.region
  network_name           = var.network_name
  subnet_name            = var.subnet_name
  subnet_cidr            = var.subnet_cidr
  pods_range_name        = var.pods_range_name
  pods_cidr              = var.pods_cidr
  services_range_name    = var.services_range_name
  services_cidr          = var.services_cidr
  proxy_only_subnet_name = var.proxy_only_subnet_name
  proxy_only_cidr        = var.proxy_only_cidr

  depends_on = [module.project_services]
}

module "firewall" {
  source                     = "./modules/firewall"
  project_id                 = var.project_id
  network                    = module.network.network_self_link
  ssh_source_ranges          = var.ssh_source_ranges
  ssh_target_tag             = var.ssh_target_tag
  web_target_tag             = var.web_target_tag
  health_check_source_ranges = var.health_check_source_ranges
  health_check_ports         = var.health_check_ports

  depends_on = [module.network]
}

module "artifact_registry" {
  source        = "./modules/artifact-registry"
  project_id    = var.project_id
  location      = var.region
  repository_id = var.artifact_registry_repository
  labels        = local.labels
  reader_members = [
    "serviceAccount:${module.iam.infra_admin_email}",
  ]

  depends_on = [module.project_services, module.iam]
}

module "gke" {
  source                     = "./modules/gke"
  project_id                 = var.project_id
  region                     = var.region
  cluster_name               = var.cluster_name
  network                    = module.network.network_self_link
  subnetwork                 = module.network.subnet_self_link
  pods_range_name            = var.pods_range_name
  services_range_name        = var.services_range_name
  release_channel            = var.release_channel
  node_locations             = var.node_locations
  node_count_per_zone        = local.node_count_per_zone
  machine_type               = var.machine_type
  disk_size_gb               = var.disk_size_gb
  disk_type                  = var.disk_type
  image_type                 = var.node_image_type
  node_service_account_email = module.iam.infra_admin_email
  node_tags                  = [var.ssh_target_tag, var.web_target_tag]
  deletion_protection        = var.deletion_protection
  labels                     = local.labels
  enable_gateway_api         = true
  gateway_api_channel        = "CHANNEL_STANDARD"

  depends_on = [
    module.project_services,
    module.network,
    module.iam,
    module.firewall,
  ]
}

# Gateway → HTTPRoute → backend-service:8080 is what creates the GKE-managed zonal NEG.
# These objects live in existing YAML; Terraform must own them so destroy removes them
# while the cluster still exists, before gke-vpc is deleted.
resource "kubernetes_manifest" "namespace" {
  manifest = yamldecode(file("${path.module}/kubernetes/namespace.yaml"))

  depends_on = [module.gke]
}

resource "kubernetes_manifest" "backend_service" {
  manifest = yamldecode(file("${path.module}/kubernetes/backend-service.yaml"))

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "frontend_service" {
  manifest = yamldecode(file("${path.module}/kubernetes/frontend-service.yaml"))

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(file("${path.module}/kubernetes/gateway.yaml"))

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "httproute" {
  manifest = yamldecode(file("${path.module}/kubernetes/http-route.yaml"))

  depends_on = [
    kubernetes_manifest.gateway,
    kubernetes_manifest.backend_service,
    kubernetes_manifest.frontend_service,
  ]
}
