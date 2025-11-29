resource "aws_ecr_repository" "app_repo_fe" {
  name                 = var.ecr_repo_name_fe
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "app_repo_be" {
  name                 = var.ecr_repo_name_be
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}