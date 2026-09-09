variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_role_name" {
  description = "IAM role name (from IAM-001) that should be granted read access to this secret"
  type        = string
}

variable "recovery_window_in_days" {
  description = "Days before a deleted secret is permanently purged (0 = immediate, no recovery window - handy for dev)"
  type        = number
  default     = 7
}

variable "secret_keys" {
  description = "Placeholder keys to seed into the secret JSON at creation - real values should be set out-of-band via console/CLI, never in tfvars/state"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}