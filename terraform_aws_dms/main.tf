terraform {
  required_version = ">=0.13.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}

data "http" "public_ipv4" {
  url = "https://checkip.amazonaws.com/"

  request_headers = {
    Accept = "text/plain"
  }
}

locals {
  external_ip_address = split("/", var.external_ip)[0]
  external_ip_is_ipv6 = strcontains(local.external_ip_address, ":")
  # `curl -s ifconfig.me` may return IPv6; appending /32 is common for IPv4 but invalid for a single IPv6 host.
  normalized_external_ip = local.external_ip_is_ipv6 && endswith(var.external_ip, "/32") ? "${local.external_ip_address}/128" : var.external_ip
  external_ipv4_cidr     = local.external_ip_is_ipv6 ? null : local.normalized_external_ip
  external_ipv6_cidr     = local.external_ip_is_ipv6 ? local.normalized_external_ip : null
  laptop_ipv4_cidr       = "${trimspace(data.http.public_ipv4.response_body)}/32"
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_ssm_parameter" "amazon_linux2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_key_pair" "source_mysql_key" {
  key_name   = "source_mysql"
  public_key = file(var.private-key-file)
}

resource "aws_security_group" "security_group_dms" {
  name        = "security_group_dms"
  description = "TCP/22"
  vpc_id      = data.aws_vpc.default_vpc.id
  ingress {
    description      = "Allow 22 from our public IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = distinct(compact(concat([local.laptop_ipv4_cidr], local.external_ipv4_cidr == null ? [] : [local.external_ipv4_cidr])))
    ipv6_cidr_blocks = local.external_ipv6_cidr == null ? [] : [local.external_ipv6_cidr]
  }
  ingress {
    description = "allow anyone on port 3306"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

#Add a rule to allow DMS replication instance to access 3306 within EC2/RDS SG
resource "aws_security_group_rule" "add_dms_replication_ip_to_sg" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [join("", [element(aws_dms_replication_instance.dms-instance.replication_instance_public_ips, 0), "/32"])]
  security_group_id = aws_security_group.security_group_dms.id
}

#Source MySQL Instance
resource "aws_instance" "source_mysql" {
  ami                         = data.aws_ssm_parameter.amazon_linux2_ami.value
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.source_mysql_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.security_group_dms.id]
  subnet_id                   = element(tolist(data.aws_subnets.default_subnet.ids), 0)
  user_data = templatefile("${path.module}/ec2_mysql_bootstrap.tftpl", {
    password = var.password
  })
}

#Target RDS Instance
resource "aws_db_instance" "target_mysql_rds" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.4"
  instance_class         = "db.t3.micro"
  db_name                = "target_mysql"
  username               = "admin"
  password               = var.password
  parameter_group_name   = "default.mysql8.4"
  vpc_security_group_ids = [aws_security_group.security_group_dms.id]
  skip_final_snapshot    = true
}
