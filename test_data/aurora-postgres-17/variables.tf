variable "region" {}
variable "role_arn" {}
variable "subnet_ids" {
  description = "List of subnet ids to add to the Postgres Instance"
  type        = list(string)
}
