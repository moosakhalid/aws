terraform {
  required_version = ">=0.13.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "linuxacademy-test"
}

data "template_file" "user_data_ec2" {
  template = file("./ec2_mysql_bootstrap")
  vars = {
    password = var.password
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
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
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
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
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.source_mysql_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.security_group_dms.id]
  subnet_id                   = element(tolist(data.aws_subnet_ids.default_subnet.ids), 0)
  user_data                   = data.template_file.user_data_ec2.rendered
}

#Target RDS Instance
resource "aws_db_instance" "target_mysql_rds" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "target_mysql"
  username               = "admin"
  password               = var.password
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.security_group_dms.id]
  skip_final_snapshot    = true
}

