resource "aws_iam_role" "default" {
  name               = "${var.project}-${var.env}-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${var.project}-${var.env}-${var.name}"
  }
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}
resource "aws_iam_policy" "default" {
  name   = "${var.project}-${var.env}-${var.name}"
  policy = var.policy
  tags = {
    Name = "${var.project}-${var.env}-${var.name}"
  }
}
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}