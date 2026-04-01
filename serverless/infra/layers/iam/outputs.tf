output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = module.iam.lambda_execution_role_arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = module.iam.lambda_execution_role_name
}
