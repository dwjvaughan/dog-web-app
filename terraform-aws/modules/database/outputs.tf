output "cluster_endpoint" {
  value = "${module.db.this_db_instance_endpoint}"
}

output "db_username" {
  value = "${var.db_username}"
}

output "db_password" {
  value = "${var.db_password}"
}

output "db_name" {
  value = "${var.db_name}"
}
