terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "full-stack-k8s-tfstate"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
