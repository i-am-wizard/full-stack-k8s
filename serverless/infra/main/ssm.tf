# Publishes deploy-time infrastructure values to SSM Parameter Store so the
# application repositories' CI/CD pipelines can discover them at deploy time
# instead of hardcoding. Terraform is the sole writer; pipelines read only.
locals {
  ssm_parameters = {
    "/${var.project_name}/frontend/bucket_name"                = module.frontend.bucket_name
    "/${var.project_name}/frontend/cloudfront_distribution_id" = module.frontend.cloudfront_distribution_id
    "/${var.project_name}/frontend/cloudfront_domain_name"     = module.frontend.cloudfront_domain_name
    "/${var.project_name}/backend/lambda_function_name"        = module.backend.lambda_function_name
    "/${var.project_name}/backend/lambda_alias"                = "live"
    "/${var.project_name}/backend/api_gateway_endpoint"        = module.backend.api_gateway_endpoint
    "/${var.project_name}/database/table_name"                 = module.database.table_name
  }
}

resource "aws_ssm_parameter" "config" {
  for_each = local.ssm_parameters

  name  = each.key
  type  = "String"
  value = each.value

  tags = var.tags
}
