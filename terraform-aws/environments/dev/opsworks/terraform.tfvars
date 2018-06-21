terragrunt = {
  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  dependencies = {
    paths = ["../network", "../database"]
  }

  terraform {
    source = "../../../modules//opsworks/"
  }
}
