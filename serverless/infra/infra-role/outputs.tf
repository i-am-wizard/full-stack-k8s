output "role_arn" {
  description = "ARN of the serverless infrastructure provisioning role (set as AWS_SERVERLESS_INFRA_ROLE_ARN)"
  value       = aws_iam_role.serverless_infra.arn
}

output "tfstate_bucket_name" {
  description = "Name of the S3 bucket holding the serverless Terraform state"
  value       = aws_s3_bucket.tfstate.id
}
