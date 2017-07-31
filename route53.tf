provider "aws" {
  region = "us-east-1"
}
resource "aws_route53_record" "chart_elb_dns" {
  zone_id = "${var.zone_id}"
  name    = "${var.zone_name}"
  type    = "A"

  alias {
    name                   = "${var.elb_name}"
    zone_id                = "${var.elb_zone_id}"
    evaluate_target_health = "false"
  }
}
output "route53_zone" {
  value = "${aws_route53_record.chart_elb_dns.zone_name}"
}
