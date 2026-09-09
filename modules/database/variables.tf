variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_subnet_ids" {
  description = "Private database subnet IDs"
  type        = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "engine_major_version" {
  description = "Major Postgres version to resolve the latest available minor for (e.g. \"16\")"
  type        = string
  default     = "16"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "app_admin"
}

variable "port" {
  type    = number
  default = 5432
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  description = "Days to retain automatic backups (0 disables backups)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred daily backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type    = string
  default = "mon:04:30-mon:05:30"
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}