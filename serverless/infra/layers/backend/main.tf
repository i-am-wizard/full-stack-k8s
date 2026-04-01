terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Layer     = "backend"
    }
  }
}

data "terraform_remote_state" "database" {
  backend = "local"
  config = {
    path = "../database/terraform.tfstate"
  }
}

data "terraform_remote_state" "iam" {
  backend = "local"
  config = {
    path = "../iam/terraform.tfstate"
  }
}

module "backend" {
  source = "../../modules/backend"

  project_name              = var.project_name
  lambda_execution_role_arn = data.terraform_remote_state.iam.outputs.lambda_execution_role_arn
  dynamodb_table_name       = data.terraform_remote_state.database.outputs.table_name
  cors_allow_origins        = var.cors_allow_origins
  tags                      = {}
}
