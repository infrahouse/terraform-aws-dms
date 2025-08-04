locals {
  engine_version  = var.engine_version
  subnet_ids_hash = sha1(join(",", var.subnet_ids))
}
