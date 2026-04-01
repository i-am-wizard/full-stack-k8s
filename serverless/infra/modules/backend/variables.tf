variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB (Rust needs very little)"
  type        = number
  default     = 128
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name to pass as environment variable"
  type        = string
}

variable "lambda_environment_variables" {
  description = "Additional environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "cors_allow_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
