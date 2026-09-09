variable "app_name" {
  description = "Application name, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security groups belong to"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_ports" {
  description = "Ports the ALB listens on (public-facing)"
  type        = list(number)
  default     = [80, 443]
}

variable "app_port" {
  description = "Port the application listens on, reachable only from the ALB"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Port the database listens on, reachable only from the app servers"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}