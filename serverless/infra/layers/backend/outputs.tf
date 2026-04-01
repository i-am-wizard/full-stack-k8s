output "api_gateway_endpoint" {
  description = "API Gateway invoke URL"
  value       = module.backend.api_gateway_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.backend.lambda_function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.backend.lambda_function_arn
}
