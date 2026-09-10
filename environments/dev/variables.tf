variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "utc-app"
}

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type = number
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "app_subnet_cidrs" {
  type = list(string)
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "nat_gateway_count" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "alb_ports" {
  type    = list(number)
  default = [80, 443]
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_port" {
  type    = number
  default = 5432
}


variable "zone_name" {
  type    = string
  default = "handart.site"
}

variable "record_name" {
  type    = string
  default = "dev.utc-app.handart.site"
}

variable "certificate_domain" {
  type    = string
  default = "*.handart.site"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # Use PriceClass_100 for lower cost, PriceClass_All for full global coverage
}

variable "logging_bucket" {
  type    = string
  default = ""
}


variable "db_engine_major_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "utcappdb"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_backup_retention_period" {
  type    = number
  default = 7
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

# This variable controls whether the S3 bucket for the application storage module is forcefully destroyed when the stack is deleted. In development environments, it is often convenient to set this to true to avoid manual cleanup, but in staging or production environments, it should be set to false to prevent accidental data loss.
variable "s3_force_destroy" {
  type    = bool
  default = true # dev only - flip to false for staging/prod
}




variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}


variable "app_secret_keys" {
  description = "Keys to seed as empty placeholders in the app secret JSON"
  type        = list(string)
  default     = ["THIRD_PARTY_API_KEY"]
}

variable "secret_recovery_window_days" {
  type    = number
  default = 0 # dev: allow immediate deletion; use 7-30 for staging/prod
}

# This variable is a list of email addresses that will be subscribed to the SNS topic for receiving alerts. 
#In development environments, it can be left empty to avoid sending unnecessary emails, but in staging or production environments, 
# It should include the email addresses of the relevant team members who need to be notified of alerts.
variable "alert_email_addresses" {
  type    = list(string)
  default = []
}


# This variable specifies the GitHub organization name for the repository that contains the application's source code.
# It is used for integration with GitHub Actions or other CI/CD pipelines that may require access to the repository.
variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

# variables.tf
variable "create_oidc_provider" {
  type    = bool
  default = true
}


variable "github_org_id" {
  type = string
}

variable "github_repo_id" {
  type = string
}