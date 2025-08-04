variable "region" {}
variable "role_arn" {
  default = null
}

variable "source_cluster_id" {}
variable "target_cluster_id" {}

variable "source_username" {}
variable "source_password" {
  sensitive = true
}
variable "target_username" {}
variable "target_password" {
  sensitive = true
}
