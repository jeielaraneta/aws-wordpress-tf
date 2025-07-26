data "aws_route53_zone" "hosted_zone" {
  name = var.route53_hosted_zone
}

resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_redirect" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "www.learning.ccst.com.au"
  type    = "A"
  alias {
    name                   = aws_route53_record.route53_record.fqdn
    zone_id                = aws_route53_record.route53_record.zone_id
    evaluate_target_health = true
  }

  depends_on = [ 
    aws_route53_record.route53_record 
  ]
}