variable "remote_state_bucket" {}
variable "vpc_remote_state_key" {}

variable "db_remote_state_key" {}

variable "aws_region" {}
variable "aws_profile" {}
variable "environment" {}

variable "common_tags" {
  type = "map"
}

variable "chef_recipe_bucket_url" {}

variable "chef_recipe_bucket_name" {}

variable "stack_name" {}

variable "web_instance_type" {}

variable "web_app_count" {}

variable "ssh_key_pair" {}
