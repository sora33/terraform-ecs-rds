variable "project" {
  description = "The project name for tagging"
  type        = string
}

variable "env" {
  description = "The environment for tagging"
  type        = string
}

variable "domain" {
  description = "The domain name for the ALB"
  type        = string
}

# =====================================================
# RDS
# =====================================================
variable "db_username" {
  description = "The username of the database"
  type        = string
  default     = "myapp"
}

variable "db_password" {
  description = "The password of the database"
  type        = string
  default     = "password"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "myapp_production"
}

variable "rails_master_key" {
  description = "The master key for Rails"
  type        = string
  sensitive   = true
}