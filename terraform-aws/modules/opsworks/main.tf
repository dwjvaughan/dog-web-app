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

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "${var.db_remote_state_key}"
    region  = "${var.aws_region}"
    profile = "${var.aws_profile}"
  }
}

resource "aws_iam_role" "opsworks_creator" {
  name = "${var.environment}-opsworks-creator-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "opsworks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "opsworks_creator" {
  name = "${var.environment}-opsworks-creator-role-policy"
  role = "${aws_iam_role.opsworks_creator.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "ec2:*",
                "iam:PassRole",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:DescribeAlarms",
                "ecs:*",
                "elasticloadbalancing:*",
                "rds:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "opsworks_creator" {
  name = "${var.environment}-opsworks"
  role = "${aws_iam_role.opsworks_creator.name}"
}

resource "aws_iam_role" "opsworks_agent" {
  name = "${var.environment}-opsworks-agent-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "opsworks_agent" {
  name = "${var.environment}-opsworks-agent-role-policy"
  role = "${aws_iam_role.opsworks_agent.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Sid": "",
      "Resource": [
        "arn:aws:s3:::${var.chef_recipe_bucket_name}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "opsworks_agent" {
  name = "${var.environment}-opsworks-agent-profile"
  role = "${aws_iam_role.opsworks_agent.name}"
}

resource "aws_opsworks_stack" "opsworks-stack" {
  name   = "${var.stack_name} - ${var.environment}"
  region = "${var.aws_region}"

  service_role_arn             = "${aws_iam_role.opsworks_creator.arn}"
  default_instance_profile_arn = "${aws_iam_instance_profile.opsworks_creator.arn}"

  custom_json = <<EOT
{
 "db": {
     "endpoint":"${data.terraform_remote_state.db.cluster_endpoint}",
     "username": "${data.terraform_remote_state.db.db_username}",
     "password": "${data.terraform_remote_state.db.db_password}",
     "db_name": "${data.terraform_remote_state.db.db_name}"
 }
}
EOT

  tags = "${merge(
    var.common_tags,
    map(
      "module", "opsworks"
    )
  )}"

  agent_version                 = "LATEST"
  configuration_manager_version = "12"
  use_custom_cookbooks          = true

  custom_cookbooks_source = {
    type = "s3"
    url  = "${var.chef_recipe_bucket_url}"
  }

  default_os               = "CentOS Linux 7"
  default_root_device_type = "ebs"

  vpc_id                       = "${data.terraform_remote_state.vpc.vpc_id}"
  default_subnet_id            = "${element(concat(data.terraform_remote_state.vpc.public_subnets, list("")), 0)}" # TODO: switch to the private subnet once #AP-6669 is implemented (as we'll no longer need to talk to zookeeper directly then)
  use_opsworks_security_groups = false

  depends_on = [
    "aws_iam_role_policy.opsworks_creator",
    "aws_iam_instance_profile.opsworks_creator",
    "aws_iam_role.opsworks_creator",
    "aws_iam_instance_profile.opsworks_agent",
    "aws_iam_role.opsworks_agent",
    "aws_iam_role_policy.opsworks_agent",
  ]
}

resource "aws_opsworks_custom_layer" "app_layer" {
  name       = "Web Application Servers - ${var.environment}"
  short_name = "${var.environment}-web-app-layer"
  stack_id   = "${aws_opsworks_stack.opsworks-stack.id}"

  auto_assign_elastic_ips = false
  auto_assign_public_ips  = true

  custom_instance_profile_arn = "${aws_iam_instance_profile.opsworks_agent.arn}"

  custom_security_group_ids = ["${aws_security_group.allow_web_traffic.id}"]

  custom_setup_recipes     = ["wordpress"]
  custom_configure_recipes = []
}

resource "aws_opsworks_instance" "web-app" {
  stack_id  = "${aws_opsworks_stack.opsworks-stack.id}"
  layer_ids = ["${aws_opsworks_custom_layer.app_layer.id}"]

  instance_type = "${var.web_instance_type}"
  state         = "running"

  hostname = "${lower(var.environment)}-web-${count.index}"

  count = "${var.web_app_count}"

  ssh_key_name = "${var.ssh_key_pair}"
  subnet_id    = "${element(data.terraform_remote_state.vpc.private_subnets, count.index)}"

  #   lifecycle {
  #     ignore_changes = ["ami_id"]
  #   }
}

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow-web-inbound"
  description = "Allow connections into the webservers"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
  var.common_tags,
  map(
    "module", "opsworks"
  )
  )}"
}

resource "aws_lb" "dog-web-app-elb" {
  name               = "${var.environment}-dog-web-app-lb"
  subnets            = ["${data.terraform_remote_state.vpc.public_subnets}"]
  security_groups    = ["${aws_security_group.allow_web_traffic.id}"]
  load_balancer_type = "application"
  internal           = false

  #   instances          = ["${aws_opsworks_instance.web-app.*.ec2_instance_id}"]

  tags = "${merge(
    var.common_tags,
    map(
      "module", "opsworks"
    )
  )}"
}

# resource "aws_elb" "dog-web-app-elb" {
#   name = "${var.environment}-dog-web-app-lb"

#   # The same availability zone as our instance
#   subnets = ["${data.terraform_remote_state.vpc.public_subnets}"]

#   security_groups = ["${aws_security_group.allow_web_traffic.id}"]

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:80/"
#     interval            = 30
#   }

#   # The instance is registered automatically

#   instances                   = ["${aws_opsworks_instance.web-app.*.ec2_instance_id}"]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400
# }

# Outbound, from the loadbalancer down to the APIs
resource "aws_lb_target_group" "dog-web-app-target-group" {
  name        = "${var.environment}-dog-web-app-lb"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = "${data.terraform_remote_state.vpc.id}"
  target_type = "ip"

  health_check {
    interval            = 30
    timeout             = 5
    port                = "80"
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  tags = "${merge(
    var.common_tags,
    map(
      "module", "opsworks"
    )
  )}"
}

resource "aws_lb_target_group_attachment" "test" {
  count            = "${var.web_app_count}"
  target_group_arn = "${aws_lb_target_group.dog-web-app-target-group.arn}"
  target_id        = "${element(aws_opsworks_instance.web-app.*.ec2_instance_id, count.index)}"
  port             = 80
}

# # Inbound, from the internet into our loadbalancer
resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = "${aws_lb.dog-web-app-elb.arn}"
  port              = "80"
  protocol          = "HTTP"

  #   ssl_policy        = "${var.ssl_policy}"
  #   certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.dog-web-app-target-group.arn}"
    type             = "forward"
  }
}
