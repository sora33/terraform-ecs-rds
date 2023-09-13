# =====================================================
# Security Group
# ===================================================== 
module "rds_sg" {
  source                   = "../security_group"
  project                  = var.project
  env                      = var.env
  name                     = "rds-sg"
  vpc_id                   = aws_vpc.main.id
  port                     = 5432
  source_security_group_id = module.ecs_sg.security_group_id
}

# =====================================================
# Subnet Group for RDS
# =====================================================
resource "aws_db_subnet_group" "for_rds" {
  name = lower("${var.project}-${var.env}-db-subnet-group")
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
  tags = {
    Name = "${var.project}-${var.env}-db-subnet-group"
  }
}

# =====================================================
# RDS Instance
# =====================================================
resource "aws_db_instance" "main" {
  identifier             = lower("${var.project}-${var.env}-db")
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = 5432
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.for_rds.name
  skip_final_snapshot    = true
  tags = {
    Name = "${var.project}-${var.env}-db"
  }
}

