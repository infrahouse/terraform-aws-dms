module "test" {
  source            = "./../../"
  source_cluster_id = var.source_cluster_id
  target_cluster_id = var.target_cluster_id
  source_username   = var.source_username
  source_password   = var.source_password
  target_username   = var.target_username
  target_password   = var.target_password
}
