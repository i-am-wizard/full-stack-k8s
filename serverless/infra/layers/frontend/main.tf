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
      Layer     = "frontend"
    }
  }
}

data "terraform_remote_state" "backend" {
  backend = "local"
  config = {
    path = "../backend/terraform.tfstate"
  }
}

module "frontend" {
  source = "../../modules/frontend"

  project_name         = var.project_name
  bucket_name          = var.frontend_bucket_name
  api_gateway_endpoint = data.terraform_remote_state.backend.outputs.api_gateway_endpoint
  tags                 = {}
}
