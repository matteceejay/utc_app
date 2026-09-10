locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(var.tags, {
    Name = "github-actions-oidc"
  })
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# NOTE: GitHub repositories created after July 15, 2026 use "immutable subject
# claims" by default - the sub claim embeds numeric owner/repo IDs
# (e.g. "repo:org@123/repo@456:ref:...") instead of plain names, to prevent
# subject recycling if a repo/org name is ever reused by someone else.
# var.github_org_id / var.github_repo_id hold those IDs (format: "name@id"),
# not the plain org/repo names - see var.github_org / var.github_repo below,
# which are unused by this condition but kept for reference/tagging elsewhere.
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only this repo, only this branch, can assume this role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org_id}/${var.github_repo_id}:ref:refs/heads/${var.allowed_branch}"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name_prefix        = "${local.name_prefix}-gh-deploy-"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-github-deploy-role"
  })
}

data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid       = "UploadDeployArtifact"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.deploy_bucket_arn}/${var.deploy_prefix}*"]
  }

  statement {
    sid    = "DiscoverInstances"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ssm:DescribeInstanceInformation",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "RunDeployCommand"
    effect = "Allow"
    actions = [
      "ssm:SendCommand",
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ssm:*:*:document/AWS-RunShellScript",
    ]
  }

  statement {
    sid    = "ReadCommandResults"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy_permissions" {
  name_prefix = "${local.name_prefix}-gh-deploy-"
  policy      = data.aws_iam_policy_document.deploy_permissions.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "deploy_permissions" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.deploy_permissions.arn
}