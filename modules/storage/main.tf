locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

# Bucket names must be globally unique - random suffix avoids collisions across accounts/envs
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ---------- S3: logs + backups ----------

resource "aws_s3_bucket" "access_logs" { # NOSONAR terraform:S6258
  bucket        = "${local.name_prefix}-access-logs-${random_id.bucket_suffix.hex}"
  force_destroy = var.s3_force_destroy

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-access-logs"
  })
}

resource "aws_s3_bucket_policy" "access_logs_delivery" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "S3ServerAccessLogsPolicy"
      Effect = "Allow"
      Principal = {
        Service = "logging.s3.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.access_logs.arn}/s3-access/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = aws_s3_bucket.this.arn
        }
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_s3_bucket_policy" "access_logs_https_only" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyInsecureTransport"
      Effect = "Deny"
      Principal = {
        AWS = "*"
      }
      Action = "s3:*"
      Resource = [
        aws_s3_bucket.access_logs.arn,
        "${aws_s3_bucket.access_logs.arn}/*"
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = var.s3_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket" "this" {
  bucket        = "${local.name_prefix}-storage-${random_id.bucket_suffix.hex}"
  force_destroy = var.s3_force_destroy

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-storage"
  })
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access/"
}

# Internal-only storage for app logs/backups. Server access logging is intentionally disabled
# here because this bucket is not public-facing and is protected by HTTPS-only policy,
# public access block, bucket ownership controls, and lifecycle rules for generated log objects.
# This makes the safer choice explicit while keeping auditability in the access-log bucket.
resource "aws_s3_bucket_policy" "https_only" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyInsecureTransport"
      Effect = "Deny"
      Principal = {
        AWS = "*"
      }
      Action = "s3:*"
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disables ACLs entirely (bucket owner always owns every object) - current AWS-recommended default
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.s3_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket     = aws_s3_bucket.this.id
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "logs-expiration"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }
  }

  rule {
    id     = "backups-tiering"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = var.backup_ia_transition_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.backup_glacier_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.backup_retention_days
    }
  }
}

# ---------- EFS: shared app-server file uploads ----------

resource "aws_security_group" "efs" {
  name_prefix = "${local.name_prefix}-efs-"
  description = "EFS SG - allows NFS only from app servers"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-efs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_app" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.app_security_group_id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  description                  = "Allow NFS from app servers"
}

resource "aws_vpc_security_group_egress_rule" "efs_all" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow all outbound"
}

resource "aws_efs_file_system" "uploads" {
  creation_token   = "${local.name_prefix}-uploads"
  encrypted        = true
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-uploads"
  })
}

resource "aws_efs_mount_target" "uploads" {
  for_each = { for idx, subnet_id in var.app_subnet_ids : tostring(idx) => subnet_id }

  file_system_id  = aws_efs_file_system.uploads.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "uploads" {
  file_system_id = aws_efs_file_system.uploads.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/uploads"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-uploads-ap"
  })
}