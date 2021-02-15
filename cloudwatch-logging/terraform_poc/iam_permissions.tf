#Create IAM Role
resource "aws_iam_role" "ec2-role" {
  name        = "AWSCloudWatchSSMRole"
  description = "Role with following managed policies CloudWatchAgentServerPolicy + AmazonEC2RoleforSSM "
  path        = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

#Attach managed policy for SSM to role
resource "aws_iam_role_policy_attachment" "attach-ssm-managed-policy" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Attach managed policy for CloudWatch agent to role
resource "aws_iam_role_policy_attachment" "attach-cw-agent-managed-policy" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Create an instance profile from role to attach to EC2
resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-role.name
}
