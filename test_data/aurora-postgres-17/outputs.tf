output "db_cluster_id" {
  value = module.aurora-postgres.db_cluster_id
}

output "db_cluster_arn" {
  value = module.aurora-postgres.db_cluster_arn
}

output "db_cluster_db_name" {
  value = module.aurora-postgres.db_cluster_db_name
}

output "db_cluster_endpoint" {
  value = module.aurora-postgres.db_cluster_endpoint
}

output "db_cluster_port" {
  value = module.aurora-postgres.db_cluster_port
}

output "master_username" {
  value = module.aurora-postgres.master_username
}

output "master_password" {
  value     = module.aurora-postgres.master_password
  sensitive = true
}

output "db_cluster_engine_version" {
  value = module.aurora-postgres.db_cluster_engine_version
}
