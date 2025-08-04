module "aurora-postgres" {
  source         = "./../aurora-postgres"
  region         = var.region
  role_arn       = var.role_arn
  subnet_ids     = var.subnet_ids
  engine_version = "17"
}
