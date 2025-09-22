
# S3 ======================================================================
module "s3_landing" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-landing"
  force_destroy = true
  tags = {
    Env = "dev"
    App = "${var.project}"
  }
}

module "s3_sor" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-sor"
  force_destroy = true
}

module "s3_sot" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-sot"
  force_destroy = true
}

module "s3_spec" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-spec"
  force_destroy = true
}

module "s3_temp" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-temp"
}

module "s3_scripts" {
  source      = "./modules/s3"
  bucket_name = "${var.project}-${var.account_id}-scripts"
}

# Database ==================================================================
resource "aws_glue_catalog_database" "sor" { 
    name = "${var.project}-sor"
    location_uri = module.s3_sor.bucket
}

resource "aws_glue_catalog_database" "sot" { 
    name = "${var.project}-sot"
    location_uri = module.s3_sor.bucket
}

resource "aws_glue_catalog_database" "spec" { 
    name = "${var.project}-spec"
    location_uri = module.s3_sor.bucket
}

# Tables =====================================================================
module "s3_sor_tables" {
  source        = "./governed/sor"
  bucket_name   = module.s3_sor.bucket
  database_name = aws_glue_catalog_database.sor.name
}

module "s3_sot_tables" {
  source        = "./governed/sot"
  bucket_name   = module.s3_sot.bucket
  database_name = aws_glue_catalog_database.sot.name
}

module "s3_spec_tables" {
  source        = "./governed/spec"
  bucket_name   = module.s3_spec.bucket
  database_name = aws_glue_catalog_database.spec.name
}