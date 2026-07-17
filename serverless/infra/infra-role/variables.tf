variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "github_repo" {
  description = "GitHub repository (org/repo format) whose Actions workflow provisions the serverless stack"
  type        = string
  default     = "i-am-wizard/full-stack-k8s"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the provisioning role"
  type        = string
  default     = "main"
}

variable "project_name" {
  description = "Project name used for resource ARN scoping"
  type        = string
  default     = "word-manager"
}

variable "tfstate_bucket_name" {
  description = "S3 bucket holding the serverless Terraform state"
  type        = string
  default     = "word-manager-serverless-infra-ak"
}
