terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Layer     = "database"
    }
  }
}

module "database" {
  source = "../../modules/database"

  table_name = var.dynamodb_table_name
  tags       = {}
}
