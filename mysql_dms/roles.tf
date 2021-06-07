#Get the DMS Assume Role Policy document
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

#Create DMS role for CloudWatch Logging
resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

#Attach DMSCloudWatchLogsRole Policy to the DMS role for CloudWatch
resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

#Create DMS VPC role for allowing creation of DMS replication instance and its network interface, policy is attached inline 
#There local provisioner with sleep is for helping with bug: https://github.com/hashicorp/terraform-provider-aws/issues/11025
#This is caused because during creation/deletion DMS VPC role with appropriate permissions is required, and currently there is no
#mechanism inside Terraform resources to either delete role after deletion of network interfaces etc which causes hung/undeleted ENI's
#or during creation tries to create DMS replication instance before the role is created and registered within AWS.
#The error may still hit, in which case, let it timeout and simply run another terraform apply

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy  = data.aws_iam_policy_document.dms_assume_role.json
  name                = "dms-vpc-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  inline_policy {
    name   = "dms-vpc-role-policy"
    policy = file("dms_policy.json")
  }
  provisioner "local-exec" {
    command = "sleep 80"
  }
}
