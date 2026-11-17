variable "region" {
  description = "AWS region for the provider"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name used in resource naming"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "myapp"
}
