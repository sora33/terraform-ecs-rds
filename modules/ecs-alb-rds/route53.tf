# =====================================================
# Route53
# =====================================================
data "aws_route53_zone" "main" {
  name = var.domain
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = data.aws_route53_zone.main.name
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# =====================================================
# 証明書情報を取得
# =====================================================
data "aws_acm_certificate" "main" {
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}