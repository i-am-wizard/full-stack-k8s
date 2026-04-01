variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for frontend static assets"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
}

variable "api_gateway_endpoint" {
  description = "API Gateway invoke URL (optional, for CloudFront API origin)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
