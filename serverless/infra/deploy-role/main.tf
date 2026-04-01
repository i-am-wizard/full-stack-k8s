terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions_serverless" {
  name               = "github-actions-serverless-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "s3_deploy" {
  statement {
    sid    = "S3FrontendSync"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-*",
      "arn:aws:s3:::${var.project_name}-*/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_deploy" {
  name   = "s3-frontend-deploy"
  role   = aws_iam_role.github_actions_serverless.id
  policy = data.aws_iam_policy_document.s3_deploy.json
}

data "aws_iam_policy_document" "cloudfront_invalidation" {
  statement {
    sid    = "CloudFrontInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations"
    ]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"]
  }
}

resource "aws_iam_role_policy" "cloudfront_invalidation" {
  name   = "cloudfront-invalidation"
  role   = aws_iam_role.github_actions_serverless.id
  policy = data.aws_iam_policy_document.cloudfront_invalidation.json
}

data "aws_iam_policy_document" "lambda_deploy" {
  statement {
    sid    = "LambdaCodeDeploy"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:PublishVersion",
      "lambda:UpdateAlias",
      "lambda:GetFunction"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_deploy" {
  name   = "lambda-code-deploy"
  role   = aws_iam_role.github_actions_serverless.id 
  policy = data.aws_iam_policy_document.lambda_deploy.json
}
