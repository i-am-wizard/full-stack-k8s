output "api_gateway_id" {
  description = "API Gateway HTTP API ID"
  value       = aws_apigatewayv2_api.backend.id
}

output "api_gateway_endpoint" {
  description = "API Gateway invoke URL"
  value       = aws_apigatewayv2_api.backend.api_endpoint
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_apigatewayv2_api.backend.execution_arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.backend.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.backend.arn
}

output "lambda_alias_arn" {
  description = "Lambda alias ARN (stable invocation target)"
  value       = aws_lambda_alias.live.arn
}
