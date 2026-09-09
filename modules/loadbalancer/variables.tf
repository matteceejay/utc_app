variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs to place the ALB in"
  type        = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "certificate_domain" {
  description = "Domain used to look up the existing ACM certificate (e.g. *.handart.site)"
  type        = string
}

variable "app_port" {
  description = "Port the app servers listen on (target group forwards here)"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle. Default is 60 seconds."
  type        = number
  default     = 60
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = ""
}

variable "access_logs_enabled" {
  description = "Whether to enable ALB access logs"
  type        = bool
  default     = false
}