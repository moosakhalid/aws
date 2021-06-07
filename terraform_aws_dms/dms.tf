#Creating a source endpoint for DMS
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source"
  endpoint_type = "source"
  engine_name   = "mariadb"
  password      = var.password
  port          = 3306
  server_name   = aws_instance.source_mysql.public_ip
  ssl_mode      = "none"
  username      = "dms"
}

#Creating a target endpoint for DMS
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target"
  endpoint_type = "target"
  engine_name   = "mysql"
  password      = var.password
  port          = 3306
  server_name   = aws_db_instance.target_mysql_rds.address
  ssl_mode      = "none"
  username      = "admin"
}


# Create a new replication instance which migrates data between source & target endpoints
resource "aws_dms_replication_instance" "dms-instance" {
  allocated_storage          = 10
  apply_immediately          = true
  auto_minor_version_upgrade = false
  multi_az                   = false
  publicly_accessible        = true
  replication_instance_class = "dms.t3.micro"
  replication_instance_id    = "dms-instance"

  tags = {
    Name = "DMS-Replication-Instance"
  }

  vpc_security_group_ids = [
    aws_security_group.security_group_dms.id
  ]
  depends_on = [aws_iam_role.dms-vpc-role]
}


# Create a new replication task for defining what type of migration we want and which tables we want to migrate
resource "aws_dms_replication_task" "dms-task" {
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.dms-instance.replication_instance_arn
  replication_task_id      = "replication-task-dms"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  table_mappings           = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"sakila\",\"table-name\":\"%\"},\"rule-action\":\"include\"}]}"

  target_endpoint_arn = aws_dms_endpoint.target.endpoint_arn
}
