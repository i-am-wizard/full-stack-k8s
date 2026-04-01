output "role_arn" {
  description = "ARN of the GitHub Actions serverless deploy role"
  value       = aws_iam_role.github_actions_serverless.arn
}
