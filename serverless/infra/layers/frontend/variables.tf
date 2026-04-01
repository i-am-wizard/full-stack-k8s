variable "project_name" {
  description = "Project name"
  type        = string
  default     = "word-manager"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for frontend assets (must be globally unique)"
  type        = string
}
