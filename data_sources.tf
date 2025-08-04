data "aws_rds_cluster" "source" {
  cluster_identifier = var.source_cluster_id
}

data "aws_rds_cluster" "target" {
  cluster_identifier = var.target_cluster_id
}

data "aws_db_subnet_group" "source" {
  name = data.aws_rds_cluster.source.db_subnet_group_name
}
