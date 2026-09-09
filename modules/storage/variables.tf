variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  description = "Private app subnet IDs - EFS mount targets are placed here, one per subnet"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "App server SG - only this SG is allowed to mount the EFS filesystem"
  type        = string
}

variable "s3_versioning_enabled" {
  type    = bool
  default = true
}

variable "s3_force_destroy" {
  description = "Allow bucket deletion even if it contains objects (handy for dev, dangerous for prod)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Days to retain objects under the logs/ prefix before expiration"
  type        = number
  default     = 90
}

variable "backup_ia_transition_days" {
  description = "Days before backups/ objects move to Standard-IA"
  type        = number
  default     = 30
}

variable "backup_glacier_transition_days" {
  description = "Days before backups/ objects move to Glacier"
  type        = number
  default     = 90
}

variable "backup_retention_days" {
  description = "Days to retain objects under the backups/ prefix before expiration"
  type        = number
  default     = 365
}

variable "efs_performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "efs_throughput_mode" {
  type    = string
  default = "bursting"
}

variable "tags" {
  type    = map(string)
  default = {}
}