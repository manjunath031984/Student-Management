variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for the regional GKE cluster and subnet."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)."
  type        = string
}

variable "infra_admin_email" {
  description = "Existing Terraform/Jenkins service account email."
  type        = string
  default     = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
}

variable "network_name" {
  description = "VPC name."
  type        = string
  default     = "gke-vpc"
}

variable "subnet_name" {
  description = "GKE subnet name."
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR for nodes."
  type        = string
  default     = "192.168.0.0/24"
}

variable "pods_range_name" {
  description = "Secondary range name for Pods."
  type        = string
  default     = "gke-pods"
}

variable "pods_cidr" {
  description = "Secondary CIDR for Pods."
  type        = string
  default     = "192.168.16.0/20"
}

variable "services_range_name" {
  description = "Secondary range name for Services."
  type        = string
  default     = "gke-services"
}

variable "services_cidr" {
  description = "Secondary CIDR for Services."
  type        = string
  default     = "192.168.32.0/20"
}

variable "proxy_only_subnet_name" {
  description = "Regional managed proxy-only subnet required by GKE Gateway (regional external Application Load Balancer)."
  type        = string
  default     = "gke-proxy-only"
}

variable "proxy_only_cidr" {
  description = "CIDR for the regional proxy-only subnet. Must not overlap node/pod/service ranges."
  type        = string
  default     = "192.168.48.0/23"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "node_count" {
  description = "Total worker nodes. GKE regional pools are per-zone; this module sets per-zone count = node_count / length(node_locations)."
  type        = number
  default     = 2
}

variable "node_locations" {
  description = "Zones that receive worker nodes."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b"]
}

variable "machine_type" {
  description = "GKE node machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Boot disk size for worker nodes."
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Boot disk type for worker nodes."
  type        = string
  default     = "pd-balanced"
}

variable "release_channel" {
  description = "GKE release channel (UNSPECIFIED, RAPID, REGULAR, STABLE, EXTENDED)."
  type        = string
  default     = "REGULAR"
}

variable "node_image_type" {
  description = "GKE node OS image. Must be a currently supported GKE image type."
  type        = string
  default     = "UBUNTU_CONTAINERD"
}

variable "ssh_source_ranges" {
  description = "Source CIDRs allowed to reach worker nodes on TCP/22. Do not silently tighten this."
  type        = list(string)
}

variable "ssh_target_tag" {
  description = "Network tag targeted by the direct SSH firewall rule."
  type        = string
  default     = "gke-student-mgmt-ssh"
}

variable "web_target_tag" {
  description = "Network tag targeted by Gateway/health-check firewall rules."
  type        = string
  default     = "gke-student-mgmt-web"
}

variable "artifact_registry_repository" {
  description = "Artifact Registry Docker repository ID."
  type        = string
  default     = "student-management"
}

variable "deletion_protection" {
  description = "GKE cluster deletion protection."
  type        = bool
  default     = false
}

variable "health_check_source_ranges" {
  description = "GCP health-check ranges for GKE Gateway / load balancer probes."
  type        = list(string)
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

variable "health_check_ports" {
  description = "Ports required by Gateway health checks (frontend 80, backend 8080)."
  type        = list(string)
  default     = ["80", "8080"]
}
