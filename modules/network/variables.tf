variable "app_name" {
  description = "Application name, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number

  validation {
    condition     = var.az_count >= 1
    error_message = "az_count must be at least 1."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (ALB tier). Each entry becomes one subnet, distributed round-robin across the chosen AZs."
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "List of CIDR blocks for private application subnets (EC2 tier)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "List of CIDR blocks for private database subnets (RDS tier)"
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create (1 for cost-saving single NAT, or up to az_count for full HA — one per AZ)"
  type        = number

  validation {
    condition     = var.nat_gateway_count >= 1
    error_message = "nat_gateway_count must be at least 1."
  }
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}