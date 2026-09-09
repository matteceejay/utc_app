data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # Slice down to only the number of AZs requested
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # AZs that will actually get a NAT Gateway
  nat_azs = slice(local.azs, 0, var.nat_gateway_count)

  # Every AZ maps to the AZ whose NAT Gateway it should route through.
  # AZs with their own NAT use it directly; extra AZs (when nat_gateway_count < az_count)
  # round-robin onto the existing NAT gateways.
  az_to_nat_az = {
    for idx, az in local.azs :
    az => local.nat_azs[idx % length(local.nat_azs)]
  }

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      az   = local.azs[idx % var.az_count]
    }
  }

  app_subnets = {
    for idx, cidr in var.app_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      az   = local.azs[idx % var.az_count]
    }
  }

  db_subnets = {
    for idx, cidr in var.db_subnet_cidrs :
    tostring(idx) => {
      cidr = cidr
      az   = local.azs[idx % var.az_count]
    }
  }

  # First public subnet key found in each AZ — that's where the NAT Gateway for that AZ lives
  public_subnet_key_by_az = {
    for az in local.azs :
    az => [for k, s in local.public_subnets : k if s.az == az][0]
  }
}

# ---------- VPC ----------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# ---------- Subnets ----------

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  for_each = local.app_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-${each.key}"
    Tier = "app"
  })
}

resource "aws_subnet" "db" {
  for_each = local.db_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-${each.key}"
    Tier = "db"
  })
}

# ---------- NAT Gateways ----------

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[local.public_subnet_key_by_az[each.key]].id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ---------- Route Tables: Public ----------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------- Route Tables: Private (one per NAT Gateway) ----------

resource "aws_route_table" "private" {
  for_each = toset(local.nat_azs)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-private-rt-${each.key}"
  })
}

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[local.az_to_nat_az[each.value.availability_zone]].id
}

resource "aws_route_table_association" "db" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[local.az_to_nat_az[each.value.availability_zone]].id
}