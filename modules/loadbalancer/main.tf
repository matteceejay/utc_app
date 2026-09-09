locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

# ----------look up and use the Existing ACM cert + hosted zone lookups ----------
# This data source will find the most recent cert for the given domain name, regardless of whether it is imported or Amazon-issued. It will error if no certs are found.
# If you have multiple certs for the same domain, you can specify the ARN directly instead of using this data source.
# Certificate must be in the same region as the ALB, and must be in the "ISSUED" state. If you have a cert in "PENDING_VALIDATION" state, you can use the AWS console to complete validation and issue it.

data "aws_acm_certificate" "this" {
  domain      = var.certificate_domain
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED", "IMPORTED"]
  most_recent = true
}


# ---------- ALB ----------

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  access_logs {
    enabled = var.access_logs_enabled
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
  }

  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb" })
}

# ---------- Target Group ----------

resource "aws_lb_target_group" "app" {
  name        = "${local.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-tg"
  })
}

# ---------- Listeners ----------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port               = 80
  protocol           = "HTTP"

  # CloudFront terminates HTTPS at the edge and talks to this ALB over plain HTTP
  # on port 80 (origin_protocol_policy = "http-only" in modules/cdn). Forwarding
  # here — not redirecting — is intentional: a redirect would send CloudFront's
  # origin request back to :443, which CloudFront does not follow, producing a
  # 301 passed straight through to the client instead of the app's response.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

