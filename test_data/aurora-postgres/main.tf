resource "random_password" "db_pass" {
  length  = 21
  special = false
}
resource "aws_rds_cluster" "default" {
  cluster_identifier_prefix   = "aurora-pg-${local.engine_version}"
  engine                      = "aurora-postgresql"
  engine_version              = local.engine_version
  database_name               = "omdb"
  apply_immediately           = true
  allow_major_version_upgrade = false

  db_subnet_group_name            = aws_db_subnet_group.default.name
  master_username                 = "foo"
  master_password                 = random_password.db_pass.result
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg.name
}

resource "aws_db_subnet_group" "default" {
  name_prefix = "aurora-pg-${local.subnet_ids_hash}"
  subnet_ids  = var.subnet_ids

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_instance" "aurora_pg_instance" {
  count                   = 1
  identifier_prefix       = "aurora-pg-${local.engine_version}-${count.index}"
  cluster_identifier      = aws_rds_cluster.default.id
  instance_class          = "db.r5.large"
  engine                  = aws_rds_cluster.default.engine
  engine_version          = aws_rds_cluster.default.engine_version
  db_subnet_group_name    = aws_db_subnet_group.default.name
  db_parameter_group_name = aws_db_parameter_group.aurora_pg.name
  apply_immediately       = true
  publicly_accessible     = true
}

resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  name_prefix = "aurora-pg-${local.engine_version}-"
  family      = "aurora-postgresql${local.engine_version}"
  description = "Custom parameter group"

  parameter {
    apply_method = "pending-reboot"
    name         = "rds.force_ssl"
    value        = "0"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora_pg" {
  name_prefix = "aurora-pg-${local.engine_version}-"
  family      = "aurora-postgresql${local.engine_version}"
  description = "Custom parameter group"
  lifecycle {
    create_before_destroy = true
  }
}
