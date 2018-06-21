terragrunt = {
  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  terraform {
    source = "../../../modules//network/"
  }
}

azs = ["eu-west-1a", "eu-west-1b"]

vpc_cidr = "10.178.0.0/23" # 10.178.0.1 - 10.178.1.254

public_subnets = ["10.178.0.0/27", "10.178.0.32/27"]

private_subnets = ["10.178.0.96/27", "10.178.0.128/27"]
