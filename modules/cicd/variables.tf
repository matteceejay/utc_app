variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  type = string
}

variable "allowed_branch" {
  type    = string
  default = "main"
}

variable "create_oidc_provider" {
  description = "Set false if the GitHub OIDC provider already exists in this AWS account (an account can only have one)"
  type        = bool
  default     = true
}

variable "deploy_bucket_arn" {
  type = string
}

variable "deploy_prefix" {
  type    = string
  default = "deploy/"
}

variable "tags" {
  type    = map(string)
  default = {}
}



variable "github_org_id" {
  description = "Immutable numeric ID of the GitHub org/owner"
  type        = string
}

variable "github_repo_id" {
  description = "Immutable numeric ID of the GitHub repository"
  type        = string
}