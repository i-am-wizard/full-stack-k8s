output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (your app URL)"
  value       = module.frontend.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.frontend.cloudfront_distribution_id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.frontend.bucket_name
}
