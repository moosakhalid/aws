output "Source-MySQL-IP" {
  description = "IP of source mysql - connect with ssh -i ~/.ssh/id_rsa ec2-user@<IP-returned>"
  value       = aws_instance.source_mysql.public_ip
}

output "RDS-Endpoint-Hostname" {
  description = "Hostname for connecting to RDS - You can connect from inside the Source-MySQL EC2 instance using mysql client"
  value       = aws_db_instance.target_mysql_rds.address
}

output "RDS-MySQL-Username" {
  value = "admin"
}

output "Source-MySQL-Username" {
  value = "root"
}
