provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Project     = local.project
      Environment = local.env
      ManagedBy   = "Terraform"
    }
  }
}