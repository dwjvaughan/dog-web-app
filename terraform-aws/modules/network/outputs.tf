output "vpc_id" {
  value = "${module.base-vpc.vpc_id}"
}

output "private_subnets" {
  value = "${module.base-vpc.private_subnets}"
}

output "private_subnets_cidrs" {
  value = "${module.base-vpc.private_subnets_cidr_blocks}"
}

output "public_subnets" {
  value = "${module.base-vpc.public_subnets}"
}

output "public_subnets_cidrs" {
  value = "${module.base-vpc.public_subnets_cidr_blocks}"
}

output "azs" {
  value = "${var.azs}"
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = "${module.base-vpc.default_security_group_id}"
}
