resource "aws_security_group" "default" {
  name   = "${var.project}-${var.env}-${var.name}"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project}-${var.env}-${var.name}"
  }
}
resource "aws_security_group_rule" "ingress" {
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.source_security_group_id == null ? null : var.source_security_group_id
  cidr_blocks              = var.cidr_blocks == null ? null : var.cidr_blocks
  security_group_id        = aws_security_group.default.id
}
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}