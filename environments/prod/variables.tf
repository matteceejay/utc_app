# Production Environment Variables
# These values are optimized for production with high availability, security, and performance

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "utc-app-prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3  # 3 AZs for maximum HA
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.20.0/24", "10.2.21.0/24", "10.2.22.0/24"]
}

variable "nat_gateway_count" {
  type    = number
  default = 3  # 1 NAT per AZ for full HA
}

variable "tags" {
  type    = map(string)
  default = {
    Project     = "utc-app"
    Environment = "production"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Compliance  = "soc2"
  }
}

# Security - strict ALB access
variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["203.0.113.0/24"]  # Replace with your office IP CIDR
  # For truly public-facing apps, keep as ["0.0.0.0/0"]
}

variable "alb_ports" {
  type    = list(number)
  default = [443]  # HTTPS only for production
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_port" {
  type    = number
  default = 5432
}

# Route53 and DNS settings
variable "zone_name" {
  type    = string
  default = "handart.site"
}

variable "record_name" {
  type    = string
  default = "utc-app.handart.site"
}

variable "certificate_domain" {
  type    = string
  default = "*.handart.site"
}

# CloudFront settings
variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_All"  # Global coverage for production
}

variable "logging_bucket" {
  type    = string
  default = "utc-app-prod-logs"  # Enable access logging
}

# RDS Database settings - production grade
variable "db_engine_major_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"  # Production-ready
}

variable "db_allocated_storage" {
  type    = number
  default = 100  # Production storage
}

variable "db_name" {
  type    = string
  default = "utcappdb_prod"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}

variable "db_multi_az" {
  type    = bool
  default = true  # Required for production HA
}

variable "db_backup_retention_period" {
  type    = number
  default = 30  # 30-day retention for compliance
}

variable "db_deletion_protection" {
  type    = bool
  default = true  # Critical for production
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false  # Always keep final snapshot
}

# S3 bucket settings
variable "s3_force_destroy" {
  type    = bool
  default = false  # NEVER force destroy in production
}

# Compute/ASG settings - high capacity
variable "instance_type" {
  type    = string
  default = "t3.large"  # Production workload
}

variable "min_size" {
  type    = number
  default = 4  # 2 per AZ minimum
}

variable "max_size" {
  type    = number
  default = 12  # Scale up for traffic spikes
}

variable "desired_capacity" {
  type    = number
  default = 4  # 2 per AZ
}

# Secrets Manager settings
variable "app_secret_keys" {
  description = "Keys to seed as empty placeholders in the app secret JSON"
  type        = list(string)
  default = [
    "JWT_SIGNING_SECRET",
    "SMTP_USERNAME",
    "SMTP_PASSWORD",
    "APP_ENCRYPTION_KEY",
    "THIRD_PARTY_API_KEY",
    "API_RATE_LIMIT_KEY",
    "WEBHOOK_SECRET"
  ]
}

variable "secret_recovery_window_days" {
  type    = number
  default = 30  # Maximum recovery window for production
}

# Alerting - production team and on-call
variable "alert_email_addresses" {
  type    = list(string)
  default = [
    "prod-alerts@example.com",
    "oncall-team@example.com",
    "sre-team@example.com"
  ]
}