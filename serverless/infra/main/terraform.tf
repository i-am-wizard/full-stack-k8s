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

  backend "s3" {
    # Provide values via -backend-config at init time:
    #   terraform init \
    #     -backend-config="bucket=my-tf-state" \
    #     -backend-config="key=serverless/terraform.tfstate" \
    #     -backend-config="region=eu-west-2"
  }
}
