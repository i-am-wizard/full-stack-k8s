variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table the Lambda needs access to"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
