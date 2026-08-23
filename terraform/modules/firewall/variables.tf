variable "project_id" {
  type = string
}

variable "network" {
  type = string
}

variable "ssh_source_ranges" {
  type = list(string)
}

variable "ssh_target_tag" {
  type = string
}

variable "web_target_tag" {
  type = string
}

variable "health_check_source_ranges" {
  type = list(string)
}

variable "health_check_ports" {
  type = list(string)
}
