aws_region = "eu-west-1"

aws_profile = "dog"

environment = "dev"

common_tags = {
  envname = "dev"
  envtype = "dog-web-app"
}

remote_state_bucket = "terraform-dog-web-app-dev"

vpc_remote_state_key = "network/terraform.tfstate"

db_remote_state_key = "database/terraform.tfstate"

opsworks_remote_state_key = "opsworks/terraform.tfstate"

chef_recipe_bucket_url = "https://s3.amazonaws.com/dog-web-app-chef/master/dog-web-app-recipes.tar.gz"

chef_recipe_bucket_name = "dog-web-app-chef"

stack_name = "DOG Web App"

web_instance_type = "t2.medium"

web_app_count = 2

ssh_key_pair = "web-app-eu-west-1"
