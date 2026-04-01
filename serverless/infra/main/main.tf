provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Project   = var.project_name
      ManagedBy = "terraform"
    })
  }
}

module "database" {
  source = "../modules/database"

  table_name = var.dynamodb_table_name
  tags       = var.tags
}

module "iam" {
  source = "../modules/iam"

  project_name       = var.project_name
  dynamodb_table_arn = module.database.table_arn
  tags               = var.tags
}

module "backend" {
  source = "../modules/backend"

  project_name              = var.project_name
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
  dynamodb_table_name       = module.database.table_name
  cors_allow_origins        = var.cors_allow_origins
  tags                      = var.tags
}

module "frontend" {
  source = "../modules/frontend"

  project_name         = var.project_name
  bucket_name          = var.frontend_bucket_name
  api_gateway_endpoint = module.backend.api_gateway_endpoint
  tags                 = var.tags
}
