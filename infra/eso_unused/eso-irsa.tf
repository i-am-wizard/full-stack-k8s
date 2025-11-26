data "aws_iam_policy_document" "eso_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "eso" {
  name               = "external-secrets-role-demo"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json
}

data "aws_iam_policy_document" "eso_sm" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]

    resources = [
      aws_secretsmanager_secret.postgres.arn
    ]
  }
}

resource "aws_iam_role_policy" "eso" {
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso_sm.json
}
