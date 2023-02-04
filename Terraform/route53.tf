resource "aws_route53_zone" "hosted_zone" {
  name = "sunmisolaganikale.me"

  tags = {
    Environment = "dev"
  }
}



# create a record set in route 53
# terraform aws route 53 record
resource "aws_route53_record" "site_domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "terraform-test.sunmisolaganikale.me"
  type    = "A"
  alias {
    name                   = aws_lb.project-load-balancer.dns_name
    zone_id                = aws_lb.project-load-balancer.zone_id
    evaluate_target_health = true
  }
}
