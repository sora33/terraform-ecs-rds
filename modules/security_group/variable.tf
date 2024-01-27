variable "project" {
  description = "The project name for tagging"
  type        = string
}

variable "env" {
  description = "The environment for tagging"
  type        = string
}

variable "name" {
  description = "The name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
variable "port" {
  description = "The port to open"
  type        = number
}
variable "cidr_blocks" {
  description = "The CIDR blocks to open"
  type        = list(string)
  default     = null
}

variable "source_security_group_id" {
  description = "The source security group ID"
  type        = string
  default     = null
}