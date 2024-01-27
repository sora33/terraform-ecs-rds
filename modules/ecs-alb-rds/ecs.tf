# =====================================================
# Security Group
# =====================================================
module "ecs_sg" {
  source      = "../security_group"
  project     = var.project
  env         = var.env
  name        = "ecs-sg"
  vpc_id      = aws_vpc.main.id
  port        = 3000
  cidr_blocks = ["0.0.0.0/0"]
}

# =====================================================
# ECS Cluster
# =====================================================
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-ecs-cluster"
  tags = {
    Name = "${var.project}-${var.env}-ecs-cluster"
  }
}

# =====================================================
# Task Definition
# =====================================================
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project}-${var.env}-ecs-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      "name" : "${var.project}-${var.env}-ecs-task",
      "image" : "${aws_ecr_repository.main.repository_url}:latest",
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "ap-northeast-1",
          "awslogs-stream-prefix" : "ecs",
          "awslogs-group" : "/ecs/${var.project}-${var.env}-ecs-log-group"
        }
      },
      "portMappings" : [
        {
          "protocol" : "tcp",
          "containerPort" : 3000
        }
      ],
      "environment" : [
        {
          "name" : "DB_HOST",
          "value" : "${aws_db_instance.main.address}"
        },
        {
          "name" : "DB_PASSWORD",
          "value" : "${var.db_password}"
        },
        {
          "name" : "RAILS_ENV",
          "value" : "production"
        },
        {
          "name" : "RAILS_LOG_TO_STDOUT",
          "value" : "1"
        },
        {
          "name" : "RAILS_SERVE_STATIC_FILES",
          "value" : "1"
        },
        {
          "name" : "RAILS_MASTER_KEY",
          "value" : "${var.rails_master_key}"
        }
      ],
    }
  ])
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn

  tags = {
    Name = "${var.project}-${var.env}-ecs-task-definition"
  }
}

# =====================================================
# ECS Service
# =====================================================
resource "aws_ecs_service" "main" {
  name                              = "${var.project}-${var.env}-ecs-service"
  cluster                           = aws_ecs_cluster.main.arn
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60
  network_configuration {
    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id
    ]
    security_groups  = [module.ecs_sg.security_group_id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.project}-${var.env}-ecs-task"
    container_port   = 3000
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# =====================================================
# IAM Role
# =====================================================
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
data "aws_iam_policy_document" "ecs_task_execution" {
  source_policy_documents = [data.aws_iam_policy.ecs_task_execution_role_policy.policy]
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}
module "ecs_task_execution_role" {
  source     = "../iam_role"
  project    = var.project
  env        = var.env
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

# =====================================================
# CloudWatch Log Group
# =====================================================
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/${var.project}-${var.env}-ecs-log-group"
  retention_in_days = 180
  tags = {
    Name = "${var.project}-${var.env}-ecs-log-group"
  }
}