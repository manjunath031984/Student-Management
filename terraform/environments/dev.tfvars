project_id        = "gcp-dev-july-2026"
region            = "us-central1"
environment       = "dev"
cluster_name      = "gke-student-mgmt-dev"
infra_admin_email = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"

network_name = "gke-vpc"
subnet_name  = "gke-subnet"
subnet_cidr  = "192.168.0.0/24"

pods_range_name     = "gke-pods"
pods_cidr           = "192.168.16.0/20"
services_range_name = "gke-services"
services_cidr       = "192.168.32.0/20"

node_count      = 2
node_locations  = ["us-central1-a", "us-central1-b"]
machine_type    = "e2-standard-2"
disk_size_gb    = 50
disk_type       = "pd-balanced"
release_channel = "REGULAR"
node_image_type = "UBUNTU_CONTAINERD"

ssh_source_ranges = ["0.0.0.0/0"]

artifact_registry_repository = "student-management"
deletion_protection          = false
