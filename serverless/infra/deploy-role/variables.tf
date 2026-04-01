variable "github_repo" {
  description = "GitHub repository (org/repo format)"
  type        = string
  default     = "i-am-wizard/full-stack-k8s"
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
