terraform {
  backend "s3" {
    bucket = "tfstate-hc-ecs"
    key    = "envs/prod/terraform.tfstate"
    region = "ap-northeast-1"
  }
}