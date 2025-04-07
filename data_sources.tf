data "aws_db_instance" "source" {
  db_instance_identifier = var.source_db_id
}

data "aws_db_instance" "target" {
  db_instance_identifier = var.target_db_id
}

data "aws_db_subnet_group" "source" {
  name = data.aws_db_instance.source.db_subnet_group
}
