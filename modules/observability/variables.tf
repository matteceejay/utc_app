variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email_addresses" {
  description = "Email addresses to subscribe to the alerts SNS topic"
  type        = list(string)
  default     = []
}

# ---- ASG ----
variable "autoscaling_group_name" {
  type = string
}

variable "asg_cpu_high_threshold" {
  type    = number
  default = 80
}

# ---- ALB / Target Group ----
variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "alb_5xx_threshold" {
  description = "Number of 5xx responses in one evaluation period before alarming"
  type        = number
  default     = 10
}

variable "alb_response_time_threshold" {
  description = "Target response time in seconds before alarming"
  type        = number
  default     = 2
}

# ---- RDS ----
variable "db_instance_id" {
  type = string
}

variable "db_cpu_high_threshold" {
  type    = number
  default = 80
}

variable "db_free_storage_threshold_bytes" {
  description = "Alarm when free storage drops below this many bytes"
  type        = number
  default     = 2147483648 # 2 GB
}

variable "db_connections_threshold" {
  type    = number
  default = 80
}

variable "evaluation_periods" {
  type    = number
  default = 2
}

variable "period_seconds" {
  type    = number
  default = 300
}

variable "tags" {
  type    = map(string)
  default = {}
}