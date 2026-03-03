variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "github_repo_infra" {
  type    = string
  default = "i-am-wizard/full-stack-k8s"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "tfstate_bucket_name" {
  type    = string
  default = "full-stack-k8s-tfstate"
}
