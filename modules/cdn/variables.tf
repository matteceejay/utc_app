variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB origin"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN - MUST be in us-east-1 for CloudFront"
  type        = string
}

variable "zone_name" {
  description = "Route 53 hosted zone name (e.g. handart.site)"
  type        = string
}

variable "record_name" {
  description = "Full FQDN the CDN will be reachable at (e.g. utc-app.handart.site)"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "logging_bucket" {
  description = "S3 bucket domain name for CloudFront access logs (e.g. my-logs-bucket.s3.amazonaws.com). Leave empty to disable logging."
  type        = string
  default     = ""
}