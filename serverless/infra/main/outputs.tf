output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (your app URL)"
  value       = module.frontend.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.frontend.cloudfront_distribution_id
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = module.frontend.bucket_name
}

output "api_gateway_endpoint" {
  description = "API Gateway invoke URL"
  value       = module.backend.api_gateway_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name (for CI/CD deploys)"
  value       = module.backend.lambda_function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.database.table_name
}
