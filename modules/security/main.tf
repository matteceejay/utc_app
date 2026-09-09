locals {
  name_prefix = "${var.app_name}-${var.environment}"

  alb_ingress_rules = {
    for pair in setproduct(var.alb_ingress_cidrs, var.alb_ports) :
    "${pair[0]}-${pair[1]}" => {
      cidr = pair[0]
      port = pair[1]
    }
  }
}

# ---------- ALB Security Group ----------

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "ALB SG - allows inbound from the internet on configured ports"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = local.alb_ingress_rules

  security_group_id = aws_security_group.alb.id
  cidr_ipv4          = each.value.cidr
  from_port          = each.value.port
  to_port            = each.value.port
  ip_protocol        = "tcp"
  description        = "Allow inbound on port ${each.value.port} from ${each.value.cidr}"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow all outbound"
}

# ---------- Application Server Security Group ----------

resource "aws_security_group" "app" {
  name_prefix = "${local.name_prefix}-app-"
  description = "App server SG - allows inbound only from the ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Allow inbound from ALB on app port ${var.app_port}"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow all outbound"
}

# ---------- Database Security Group ----------

resource "aws_security_group" "db" {
  name_prefix = "${local.name_prefix}-db-"
  description = "Database SG - allows inbound only from app servers"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow inbound from app servers on db port ${var.db_port}"
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow all outbound"
}