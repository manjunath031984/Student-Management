variable "project_id" {
  type = string
}

variable "infra_admin_email" {
  type = string
}

variable "node_sa_account_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
