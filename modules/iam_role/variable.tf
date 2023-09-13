variable "project" {
  description = "The project name for tagging"
  type        = string
}
variable "env" {
  description = "The environment for tagging"
  type        = string
}
variable "name" {
  description = "The name for tagging"
  type        = string
}
variable "policy" {
  description = "The policy for the IAM role"
  type        = string
}
variable "identifier" {
  description = "The identifier for the IAM role"
  type        = string
}