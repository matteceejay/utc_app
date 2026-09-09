# Staging Environment Variables
# These values are optimized for staging with higher reliability than dev but cost-conscious

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "utc-app-staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.20.0/24", "10.1.21.0/24"]
}

variable "nat_gateway_count" {
  type    = number
  default = 2  # 2 NATs for HA testing
}

variable "tags" {
  type    = map(string)
  default = {
    Project     = "utc-app"
    Environment = "staging"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Security - restrict ALB access
variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["203.0.113.0/24"]  # Replace with your office IP CIDR
}

variable "alb_ports" {
  type    = list(number)
  default = [80, 443]  # Both HTTP and HTTPS for staging
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
  default = "utc-app-staging.handart.site"
}

variable "certificate_domain" {
  type    = string
  default = "*.handart.site"
}

# CloudFront settings
variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"  # US/Europe only for staging
}

variable "logging_bucket" {
  type    = string
  default = ""  # Disable logging for staging to save costs
}

# RDS Database settings - upgraded for staging
variable "db_engine_major_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"  # Upgraded from micro
}

variable "db_allocated_storage" {
  type    = number
  default = 50  # Increased storage
}

variable "db_name" {
  type    = string
  default = "utcappdb_staging"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}

variable "db_multi_az" {
  type    = bool
  default = true  # HA for staging
}

variable "db_backup_retention_period" {
  type    = number
  default = 14  # 2 weeks retention
}

variable "db_deletion_protection" {
  type    = bool
  default = true  # Protect against accidental deletion
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false  # Keep final snapshot
}

# S3 bucket settings
variable "s3_force_destroy" {
  type    = bool
  default = false  # Don't force destroy in staging
}

# Compute/ASG settings
variable "instance_type" {
  type    = string
  default = "t3.medium"  # Upgraded from micro
}

variable "min_size" {
  type    = number
  default = 3  # Higher min for availability
}

variable "max_size" {
  type    = number
  default = 8
}

variable "desired_capacity" {
  type    = number
  default = 3
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
    "THIRD_PARTY_API_KEY"
  ]
}

variable "secret_recovery_window_days" {
  type    = number
  default = 7  # 7-day recovery window for staging
}

# Alerting - staging team
variable "alert_email_addresses" {
  type    = list(string)
  default = [
    "dev-team@example.com",
    "staging-alerts@example.com"
  ]
}