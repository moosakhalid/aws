provider "aws" {
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs            = [join("", [var.region, "a"])]
  public_subnets = ["10.0.101.0/24"]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH into VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

data "aws_ssm_parameter" "amazon-linux-2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_key_pair" "ec2-kp" {
  key_name   = "Keypair for EC2 instance"
  public_key = file(var.ssh_pub_key_path)
}

resource "aws_instance" "ec2-vm" {
  count                = fileexists("bootstrap.sh") ? var.vm-count : 0
  ami                  = data.aws_ssm_parameter.amazon-linux-2.value
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.public_subnets[0]
  key_name             = aws_key_pair.ec2-kp.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name
  security_groups      = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "CW-Bootstrap"
  }
  timeouts {
    create = "3m"
  }
  # user_data = fileexists("bootstrap.sh") ? file("bootstrap.sh") : null
  provisioner "remote-exec" {
    script = "./bootstrap.sh"
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      timeout     = "3m"
      private_key = file(var.ssh_key_path)
    }
  }
  provisioner "file" {
    content     = templatefile("amazon-cloudwatch-agent.tpl", { region = var.region })
    destination = "/home/ec2-user/amazon-cloudwatch-agent.json"
    connection {
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file(var.ssh_key_path)
      type        = "ssh"
      timeout     = "50s"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ec2-user/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/",
      "sudo chown root:root /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "sudo systemctl restart amazon-cloudwatch-agent"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      timeout     = "1m"
      private_key = file(var.ssh_key_path)
    }
  }

}
