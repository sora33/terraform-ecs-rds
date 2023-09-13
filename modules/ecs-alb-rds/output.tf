output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "rds_identifier" {
  value = aws_db_instance.main.identifier
}