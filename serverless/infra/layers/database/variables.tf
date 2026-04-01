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

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "word-manager-table"
}
