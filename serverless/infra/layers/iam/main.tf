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
      Layer     = "iam"
    }
  }
}

data "terraform_remote_state" "database" {
  backend = "local"
  config = {
    path = "../database/terraform.tfstate"
  }
}

module "iam" {
  source = "../../modules/iam"

  project_name       = var.project_name
  dynamodb_table_arn = data.terraform_remote_state.database.outputs.table_arn
  tags               = {}
}
