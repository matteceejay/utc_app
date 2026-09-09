locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # Placeholder JSON - one empty string per declared key, so the secret exists with the
  # right shape immediately. Real values get set afterward outside of Terraform.
  placeholder_json = jsonencode({
    for k in var.secret_keys : k => ""
  })
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${local.name_prefix}-app-secrets"
  description             = "Application-level secrets for ${local.name_prefix} (API keys, third-party tokens, etc.) - NOT the DB master password, which RDS manages separately"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = local.placeholder_json

  # Terraform seeds the placeholder once; real values get set via console/CLI/CI afterward
  # and Terraform will never overwrite them on subsequent applies.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ---------- Read-only access for the app instance role ----------

data "aws_iam_policy_document" "read_app_secret" {
  statement {
    sid    = "ReadAppSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.app.arn]
  }
}

resource "aws_iam_policy" "read_app_secret" {
  name_prefix = "${local.name_prefix}-app-secret-read-"
  description = "Read-only access to the ${local.name_prefix} app secret"
  policy      = data.aws_iam_policy_document.read_app_secret.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "read_app_secret" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.read_app_secret.arn
}