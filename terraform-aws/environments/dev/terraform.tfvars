terragrunt = {
  remote_state {
    backend = "s3"

    config {
      bucket  = "terraform-dog-web-app-dev"
      key     = "${path_relative_to_include()}/terraform.tfstate"
      region  = "eu-west-1"
      encrypt = true
      profile = "dog"
    }
  }

  terraform {
    extra_arguments "bucket" {
      commands = ["${get_terraform_commands_that_need_vars()}"]

      optional_var_files = [
        "${get_tfvars_dir()}/${find_in_parent_folders("global.tfvars", "ignore")}",
      ]
    }
  }
}
