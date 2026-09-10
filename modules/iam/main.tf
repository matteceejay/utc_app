locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

# ---------- Trust policy: only EC2 can assume this role ----------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_instance" {
  name_prefix        = "${local.name_prefix}-app-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-role"
  })
}

resource "aws_iam_instance_profile" "app_instance" {
  name_prefix = "${local.name_prefix}-app-"
  role        = aws_iam_role.app_instance.name

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-instance-profile"
  })
}

# ---------- S3: read/write only within this bucket, only under logs/ and uploads/; read-only under deploy/ ----------

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "ListBucketScopedPrefixes"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["logs/*", "uploads/*", "deploy/*"]
    }
  }

  statement {
    sid    = "ReadWriteScopedPrefixes"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${var.s3_bucket_arn}/logs/*",
      "${var.s3_bucket_arn}/uploads/*",
    ]
  }

  statement {
    sid       = "ReadDeployArtifact"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/deploy/*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "${local.name_prefix}-s3-"
  description = "Least-privilege S3 access for ${local.name_prefix} app instances"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.app_instance.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# ---------- EFS: mount + read/write only via the app's access point ----------

data "aws_iam_policy_document" "efs_access" {
  statement {
    sid    = "EFSClientAccessViaAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = [var.efs_file_system_arn]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [var.efs_access_point_arn]
    }
  }
}

resource "aws_iam_policy" "efs_access" {
  name_prefix = "${local.name_prefix}-efs-"
  description = "Least-privilege EFS access (scoped to one access point) for ${local.name_prefix} app instances"
  policy      = data.aws_iam_policy_document.efs_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "efs_access" {
  role       = aws_iam_role.app_instance.name
  policy_arn = aws_iam_policy.efs_access.arn
}

# ---------- Secrets Manager: read only the DB master secret ----------

data "aws_iam_policy_document" "db_secret_access" {
  statement {
    sid    = "ReadDbMasterSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_policy" "db_secret_access" {
  name_prefix = "${local.name_prefix}-db-secret-"
  description = "Read-only access to the RDS master secret for ${local.name_prefix}"
  policy      = data.aws_iam_policy_document.db_secret_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "db_secret_access" {
  role       = aws_iam_role.app_instance.name
  policy_arn = aws_iam_policy.db_secret_access.arn
}

# ---------- SSM Session Manager (optional but recommended - no SSH/key pairs needed) ----------

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}