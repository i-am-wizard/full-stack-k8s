variable "github_repos" {
  description = "GitHub repositories (org/repo format) whose Actions workflows may assume the deploy role"
  type        = list(string)
  default = [
    "i-am-wizard/word-manager-fe",
    "i-am-wizard/word-manager-rust-be",
  ]
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the role"
  type        = string
  default     = "main"
}

variable "project_name" {
  description = "Project name used for resource ARN scoping"
  type        = string
  default     = "word-manager"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}
