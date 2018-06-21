variable "remote_state_bucket" {}
variable "vpc_remote_state_key" {}
variable "aws_region" {}
variable "aws_profile" {}
variable "environment" {}

variable "common_tags" {
  type = "map"
}

variable "db_username" {}
variable "db_password" {}
variable "db_instance_type" {}
variable "db_name" {}
variable "db_identifier_prefix" {}

variable "db_access_cidrs" {
  type = "list"
}
