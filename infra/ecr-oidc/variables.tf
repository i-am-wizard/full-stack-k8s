variable "github_repo_fe" {
  type    = string
  default = "i-am-wizard/word-manager-fe"
}

variable "github_repo_be" {
  type    = string
  default = "i-am-wizard/word-manager-be"
}

variable "ecr_repo_name_fe" {
  type    = string
  default = "word-manager-frontend"
}

variable "ecr_repo_name_be" {
  type    = string
  default = "word-manager-backend"
}

variable "github_branch" {
  type    = string
  default = "main"
}
