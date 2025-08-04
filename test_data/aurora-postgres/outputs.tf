output "db_cluster_id" {
  value = aws_rds_cluster.default.id
}

output "db_cluster_arn" {
  value = aws_rds_cluster.default.arn
}

output "db_cluster_db_name" {
  value = aws_rds_cluster.default.database_name
}

output "db_cluster_endpoint" {
  value = aws_rds_cluster.default.endpoint
}

output "db_cluster_port" {
  value = aws_rds_cluster.default.port
}

output "master_username" {
  value = aws_rds_cluster.default.master_username
}

output "master_password" {
  value     = aws_rds_cluster.default.master_password
  sensitive = true
}

output "db_cluster_engine_version" {
  value = aws_rds_cluster.default.engine_version
}
