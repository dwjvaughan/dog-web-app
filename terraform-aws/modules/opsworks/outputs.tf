output "elb_endpoint" {
  value = "${aws_lb.dog-web-app-elb.dns_name}"
}
