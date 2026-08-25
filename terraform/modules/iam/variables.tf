variable "project_id" {
  type = string
}

variable "infra_admin_email" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
