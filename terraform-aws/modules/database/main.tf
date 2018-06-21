provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "${var.vpc_remote_state_key}"
    region  = "${var.aws_region}"
    profile = "${var.aws_profile}"
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.db_identifier_prefix}${var.environment}"

  engine = "mysql"

  engine_version = "5.7.19"
  instance_class = "${var.db_instance_type}"

  allocated_storage = 5

  name     = "${var.db_name}"
  username = "${var.db_username}"
  password = "${var.db_password}"
  port     = "3306"

  # iam_database_authentication_enabled = true

  vpc_security_group_ids = ["${aws_security_group.allow_mysql_inbound.id}"]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"
  tags = "${merge(
  var.common_tags,
  map(
    "module", "database"
  )
  )}"
  # DB subnet group
  subnet_ids = ["${data.terraform_remote_state.vpc.public_subnets}"]
  # DB parameter group
  family = "mysql5.7"
  # DB option group
  major_engine_version = "5.7"
  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.db_identifier_prefix}${var.environment}-final"
}

resource "aws_security_group" "allow_mysql_inbound" {
  name        = "allow-mysql-inbound"
  description = "Allow connections into the MySQL Database"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${concat(data.terraform_remote_state.vpc.private_subnets_cidrs,var.db_access_cidrs)}"]
  }

  tags = "${merge(
  var.common_tags,
  map(
    "module", "database"
  )
  )}"
}
