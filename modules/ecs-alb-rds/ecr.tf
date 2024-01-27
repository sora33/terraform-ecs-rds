# =====================================================
# ECR
# =====================================================
resource "aws_ecr_repository" "main" {
  name = lower("${var.project}-${var.env}-ecr")
}

# =====================================================
# Lifecycle Policy for ECR
# =====================================================
# latestタグは保持
# それ以外は10個保持
resource "aws_ecr_lifecycle_policy" "main_repo" {
  repository = aws_ecr_repository.main.name

  policy = <<EOF
    {
        "rules": [
          {
              "rulePriority": 1,
              "description": "Keep 'latest' images indefinitely",
              "selection": {
                  "tagStatus": "tagged",
                  "tagPrefixList": ["latest"],
                  "countType": "imageCountMoreThan",
                  "countNumber": 1
              },
              "action": {
                  "type": "expire"
              }
          },
          {
              "rulePriority": 2,
              "description": "Keep up to 10 of every image",
              "selection": {
                  "tagStatus": "any",
                  "countType": "imageCountMoreThan",
                  "countNumber": 10
              },
              "action": {
                  "type": "expire"
              }
          }
      ]
    }
    EOF
}