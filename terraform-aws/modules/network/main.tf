provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

module "base-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "DOG Web App - ${var.environment}"

  enable_dns_hostnames = true

  azs = ["${var.azs}"]

  cidr            = "${var.vpc_cidr}"
  public_subnets  = ["${var.public_subnets}"]
  private_subnets = ["${var.private_subnets}"]

  enable_nat_gateway = false

  enable_vpn_gateway = false
  enable_s3_endpoint = false

  tags = "${merge(
    var.common_tags,
    map(
      "module", "network"
    )
  )}"
}
