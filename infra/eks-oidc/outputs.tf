output "infra_role_arn" {
  description = "ARN of the IAM role for GitHub Actions infra deployments"
  value       = aws_iam_role.github_actions_infra.arn
}
