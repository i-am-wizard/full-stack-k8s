output "role_arn" {
  description = "ARN of the serverless infrastructure provisioning role (set as AWS_SERVERLESS_INFRA_ROLE_ARN)"
  value       = aws_iam_role.serverless_infra.arn
}
