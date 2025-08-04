variable "source_cluster_id" {
  description = "Source cluster identifier."
}

variable "target_cluster_id" {
  description = "Source cluster identifier."
}

variable "source_username" {
  description = "Username to connect to the source database. If not specified, the module will get it from the master_user_secret attribute."
  default     = null
}

variable "source_password" {
  description = "Password to connect to the source database. If not specified, the module will get it from the master_user_secret attribute."
  default     = null
}

variable "target_username" {
  description = "Username to connect to the target database. If not specified, the module will get it from the master_user_secret attribute."
  default     = null
}

variable "target_password" {
  description = "Password to connect to the target database. If not specified, the module will get it from the master_user_secret attribute."
  default     = null
}
