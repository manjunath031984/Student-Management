variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "repository_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "reader_members" {
  type    = list(string)
  default = []
}
