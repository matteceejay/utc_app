locals {
  name_prefix = "${var.app_name}-${var.environment}"
  default_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

# ---- Secret references (app reads these at runtime via the instance role - never baked in) ----
    cat >> /etc/environment <<ENV
    APP_SECRET_ARN=${var.app_secret_arn}
    DB_SECRET_ARN=${var.db_secret_arn}
    ENV

    # ---- EFS mount (uploads) ----
    dnf install -y amazon-efs-utils
    mkdir -p ${var.efs_mount_path}
    cat >> /etc/fstab <<FSTAB
    ${var.efs_file_system_id}:/ ${var.efs_mount_path} efs _netdev,tls,iam,accesspoint=${var.efs_access_point_id} 0 0
    FSTAB
    mount -a -t efs
    # ---- Placeholder app bootstrap ----
    echo "Placeholder user data for ${local.name_prefix} - replace with actual app bootstrap"
  EOF
  user_data = var.user_data != null ? var.user_data : local.default_user_data
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  default_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

# ---- Secret references (app reads these at runtime via the instance role - never baked in) ----
    cat >> /etc/environment <<ENV
    APP_SECRET_ARN=${var.app_secret_arn}
    DB_SECRET_ARN=${var.db_secret_arn}
    ENV

    # ---- EFS mount (uploads) ----
    dnf install -y amazon-efs-utils
    mkdir -p ${var.efs_mount_path}
    cat >> /etc/fstab <<FSTAB
    ${var.efs_file_system_id}:/ ${var.efs_mount_path} efs _netdev,tls,iam,accesspoint=${var.efs_access_point_id} 0 0
    FSTAB
    mount -a -t efs
    # ---- Placeholder app bootstrap ----
    echo "Placeholder user data for ${local.name_prefix} - replace with actual app bootstrap"
  EOF
  user_data = var.user_data != null ? var.user_data : local.default_user_data
}

# This stand up a sub python HTTP server on port 8080 and serves a simple text response for testing purposes. It is a temporary placeholder for the actual application deployment and should be replaced with the real application bootstrap process in production environments.
# this is to let up prove requirements 1, 2, and 4 for real
# Just enough to prove the path end-to-end, but not a real app deployment. The real app deployment should be done via a separate process (e.g., CI/CD pipeline) that deploys the actual application code and dependencies to the EC2 instances in the ASG.

/*
locals {
  name_prefix = "${var.app_name}-${var.environment}"

  default_user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # ---- Secret references (app reads these at runtime via the instance role - never baked in) ----
    cat >> /etc/environment <<ENV
    APP_SECRET_ARN=${var.app_secret_arn}
    DB_SECRET_ARN=${var.db_secret_arn}
    ENV

    # ---- EFS mount (uploads) ----
    dnf install -y amazon-efs-utils

    mkdir -p ${var.efs_mount_path}

    cat >> /etc/fstab <<FSTAB
    ${var.efs_file_system_id}:/ ${var.efs_mount_path} efs _netdev,tls,iam,accesspoint=${var.efs_access_point_id} 0 0
    FSTAB

    mount -a -t efs

    # ---- Stub app (TEMPORARY - proves the path end-to-end; replace with real app deploy) ----
    mkdir -p /opt/stub-app

    cat > /opt/stub-app/server.py <<'PYEOF'
    import http.server
    import socketserver

    PORT = ${var.app_port}

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"utc-app stub - OK\n")

        def log_message(self, format, *args):
            pass  # keep instance logs quiet

    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        httpd.serve_forever()
    PYEOF

    cat > /etc/systemd/system/stub-app.service <<'UNITEOF'
    [Unit]
    Description=Temporary stub app for utc-app
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/stub-app/server.py
    Restart=always
    User=nobody

    [Install]
            WantedBy=multi-user.target
            UNITEOF

            systemctl daemon-reload
            systemctl enable --now stub-app

            echo "Stub app running on port ${var.app_port} for ${local.name_prefix}"
        EOF

        user_data = var.user_data != null ? var.user_data : local.default_user_data
        }
*/

locals {
  name_prefix = "${var.app_name}-${var.environment}"
  user_data   = var.user_data != null ? var.user_data : ""
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

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id]
  }

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