module "main" {
  source = "../../modules/ecs-alb-rds"
  project          = local.project
  env              = local.env
  domain           = "atelier-sora3.com"
  db_username      = "myapp"
  db_password      = "password" # TODO: Change this to a secure password
  rails_master_key = var.rails_master_key
}

output "alb_dns_name" {
  value = module.main.alb_dns_name
}
output "rds_identifier" {
  value = module.main.rds_identifier
}