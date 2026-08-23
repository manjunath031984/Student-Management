variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "release_channel" {
  type = string
}

variable "node_locations" {
  type = list(string)
}

variable "node_count_per_zone" {
  type = number
}

variable "machine_type" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "disk_type" {
  type = string
}

variable "image_type" {
  type = string
}

variable "node_service_account_email" {
  type = string
}

variable "node_tags" {
  type = list(string)
}

variable "deletion_protection" {
  type = bool
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "enable_gateway_api" {
  type    = bool
  default = true
}

variable "gateway_api_channel" {
  type    = string
  default = "CHANNEL_STANDARD"
}
