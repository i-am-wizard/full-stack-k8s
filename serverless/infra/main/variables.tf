variable "project_name" {
  description = "Project name used for resource naming"
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

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "word-manager-table"
}

variable "cors_allow_origins" {
  description = "Allowed origins for API Gateway CORS"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
