terragrunt = {
  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  dependencies = {
    paths = ["../network"]
  }

  terraform {
    source = "../../../modules//database/"
  }
}

db_instance_type = "db.t2.small"

db_access_cidrs = ["0.0.0.0/0"]

db_username = "root"

db_identifier_prefix = "dog-web-app-"

db_name = "wordpress"

# Set by setting environment variable TF_VAR_db_password
#db_password = "j5nWdjbXwvBjP6nu"

