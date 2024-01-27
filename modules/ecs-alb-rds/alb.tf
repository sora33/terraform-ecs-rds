# =====================================================
# Security Group
# =====================================================
module "http_sg" {
  source      = "../security_group"
  project     = var.project
  env         = var.env
  name        = "http-sg"
  vpc_id      = aws_vpc.main.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
module "https_sg" {
  source      = "../security_group"
  project     = var.project
  env         = var.env
  name        = "https-sg"
  vpc_id      = aws_vpc.main.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}
# =====================================================
# ALB Log Bucket and Policy
# =====================================================

resource "aws_s3_bucket" "alb_log" {
  bucket        = lower("${var.project}-${var.env}-alb-log")
  force_destroy = false
  tags = {
    Name = "${var.project}-${var.env}-alb-log"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "alb_log_lifecycle" {
  bucket = aws_s3_bucket.alb_log.id
  rule {
    id     = "rule-DeleteAfter180Days"
    status = "Enabled"

    expiration {
      days = 180
    }
  }
}
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}


data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
    principals {
      type        = "AWS"
      identifiers = ["582318560864"] # Tokyo Region
    }
  }
}

# =====================================================
# ALB
# =====================================================

resource "aws_lb" "main" {
  name                       = "${var.project}-${var.env}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id
  ]
  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id
  ]
  access_logs {
    bucket  = aws_s3_bucket.alb_log.bucket
    prefix  = "alb"
    enabled = true
  }
  tags = {
    Name = "${var.project}-${var.env}-alb"
  }
}

# =====================================================
# ALB Listener
# =====================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name = "${var.project}-${var.env}-alb-listener-http"
  }
}
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.main.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "ok! HTTPS is working!"
      status_code  = "200"
    }
  }
  tags = {
    Name = "${var.project}-${var.env}-alb-listener-https"
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# =====================================================
# ALB Target Group
# =====================================================
resource "aws_lb_target_group" "main" {
  name                 = "${var.project}-${var.env}-target-group"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300
  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  depends_on = [aws_lb.main]
  tags = {
    Name = "${var.project}-${var.env}-target-group"
  }
}