variable "project_id" {
  type    = string
  default = "gcp-dev-july-2026"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "bucket_name" {
  type    = string
  default = "gcp-dev-july-2026-terraform-state"
}

variable "infra_admin_email" {
  type    = string
  default = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
}
