variable "azs" {
    description = "List of Availability Zones to use"
    type = "list"
}

variable "vpc_cidr" {
    description = "CIDR range for the VPC"
}

variable "public_subnets" {
    description = "List of CIDR ranges for the Public Subnets"
    type = "list"
}

variable "private_subnets" {
    description = "List of CIDR ranges for the Private Subnets"
    type = "list"
}

variable "aws_region" {}
variable "aws_profile" {}
variable "environment" {}
variable "common_tags" {
    type = "map"
}