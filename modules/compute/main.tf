locals {
  name_prefix = "${var.app_name}-${var.environment}"

  default_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # ---- App environment: secret ARNs + DB connection info ----
    cat > /etc/utc-app.env <<ENV
    AWS_DEFAULT_REGION=${var.aws_region}
    APP_SECRET_ARN=${var.app_secret_arn}
    DB_SECRET_ARN=${var.db_secret_arn}
    DB_HOST=${var.db_host}
    DB_PORT=${var.db_port}
    DB_NAME=${var.db_name}
    ENV

    # ---- EFS mount (uploads) ----
    dnf install -y amazon-efs-utils python3 python3-pip unzip

    mkdir -p ${var.efs_mount_path}

    cat >> /etc/fstab <<FSTAB
    ${var.efs_file_system_id}:/ ${var.efs_mount_path} efs _netdev,tls,iam,accesspoint=${var.efs_access_point_id} 0 0
    FSTAB

    mount -a -t efs

    # ---- App deploy mechanism (invoked by GitHub Actions via SSM on every push) ----
    mkdir -p /opt/utc-app

    cat > /usr/local/bin/deploy-app.sh <<'SCRIPT'
    #!/bin/bash
    set -euxo pipefail

    DEPLOY_BUCKET="${var.deploy_bucket}"
    DEPLOY_KEY="${var.deploy_prefix}latest.zip"
    APP_DIR="/opt/utc-app"

    aws s3 cp "s3://$DEPLOY_BUCKET/$DEPLOY_KEY" /tmp/app.zip
    rm -rf "$APP_DIR"/*
    unzip -o /tmp/app.zip -d "$APP_DIR"

    cd "$APP_DIR"
    python3 -m venv venv
    ./venv/bin/pip install --upgrade pip -q
    ./venv/bin/pip install -r requirements.txt -q

    systemctl restart utc-app
    SCRIPT

    chmod +x /usr/local/bin/deploy-app.sh

    cat > /etc/systemd/system/utc-app.service <<UNITEOF
    [Unit]
    Description=UTC Career Prep app
    After=network.target

    [Service]
    WorkingDirectory=/opt/utc-app
    EnvironmentFile=/etc/utc-app.env
    ExecStart=/opt/utc-app/venv/bin/gunicorn -w 2 -b 0.0.0.0:${var.app_port} wsgi:app
    Restart=always
    User=ec2-user

    [Install]
    WantedBy=multi-user.target
    UNITEOF

    systemctl daemon-reload
    systemctl enable utc-app

    # Pull the artifact now if one already exists in S3; otherwise the service
    # stays stopped until the first GitHub Actions deploy runs.
    if aws s3api head-object --bucket "${var.deploy_bucket}" --key "${var.deploy_prefix}latest.zip" 2>/dev/null; then
      /usr/local/bin/deploy-app.sh
    else
      echo "No deployed artifact yet at s3://${var.deploy_bucket}/${var.deploy_prefix}latest.zip"
    fi
  EOF

  user_data = var.user_data != null ? var.user_data : local.default_user_data
}

# Always resolves to the latest Amazon Linux 2023 AMI at apply time - no hardcoded/deprecated AMI IDs
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_security_group_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type            = "gp3"
      encrypted              = true
      delete_on_termination  = true
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-app"
    })
  }

  update_default_version = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-lt"
  })
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type          = "ELB"
  health_check_grace_period  = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Scale automatically based on traffic load ----------

resource "aws_autoscaling_policy" "request_count" {
  name                   = "${local.name_prefix}-target-tracking-requests"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label          = "${var.alb_arn_suffix}/${var.target_group_arn_suffix}"
    }
    target_value     = var.target_requests_per_target
    disable_scale_in = false
  }
}

