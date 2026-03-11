# Terraform AWS DMS Demo

This Terraform module creates a simple AWS Database Migration Service (DMS) demo environment in `us-east-1`.

It provisions:
- A source EC2 instance running MariaDB with the Sakila sample database loaded
- A target MySQL RDS instance
- A security group for SSH and MySQL traffic
- IAM roles required by DMS
- A DMS replication instance
- DMS source and target endpoints
- A DMS replication task

## Prerequisites

Make sure you have:

1. Terraform installed
2. AWS CLI installed
3. An AWS account with permissions to create EC2, RDS, IAM, DMS, and security group resources
4. An SSH key pair where the public key exists at `~/.ssh/id_rsa.pub`

If you do not already have an SSH key pair, create one:

```bash
ssh-keygen -t rsa
```

This module reads the public key from `~/.ssh/id_rsa.pub` and you will use the matching private key `~/.ssh/id_rsa` to SSH into the EC2 instance.

## Step 1: Configure your AWS profile

This module uses the AWS CLI `default` profile unless you override it.

To configure the default profile:

```bash
aws configure
```

If you want to use a different AWS profile, pass it explicitly during `plan`, `apply`, and `destroy`.

## Step 2: Clone and enter the project

```bash
git clone https://github.com/moosakhalid/aws.git
cd aws/terraform_aws_dms
```

## Step 3: Initialize Terraform

```bash
terraform init
```

## Step 4: Validate the configuration

```bash
terraform validate
```

## Step 5: Get your public IP

This module restricts SSH access to the EC2 source instance using your public IP.

```bash
curl -s ifconfig.me
```

If the command returns an IPv4 address, use `/32`.

Example:

```bash
203.0.113.10/32
```

If the command returns an IPv6 address, use `/128`.

Example:

```bash
2001:db8::1234/128
```

## Step 6: Review the plan

For IPv4:

```bash
terraform plan -var="external_ip=$(curl -s ifconfig.me)/32"
```

For IPv6:

```bash
terraform plan -var="external_ip=$(curl -s ifconfig.me)/128"
```

With a custom AWS profile:

```bash
terraform plan \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=YOUR_PUBLIC_IP_CIDR"
```

## Step 7: Apply the infrastructure

For IPv4:

```bash
terraform apply -var="external_ip=$(curl -s ifconfig.me)/32"
```

For IPv6:

```bash
terraform apply -var="external_ip=$(curl -s ifconfig.me)/128"
```

With a custom AWS profile:

```bash
terraform apply \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=YOUR_PUBLIC_IP_CIDR"
```

Type `yes` when prompted.

## Step 8: Check Terraform outputs

After apply completes, run:

```bash
terraform output
```

Important outputs:
- `Source-MySQL-IP`: public IP of the EC2 instance hosting the source MariaDB database
- `RDS-Endpoint-Hostname`: hostname of the target MySQL RDS instance
- `RDS-MySQL-Username`: `admin`
- `Source-MySQL-Username`: `root`

Note:
- The source EC2 host runs MariaDB and is initialized with a `root` password from `var.password`
- A separate MySQL user named `dms` is also created for the DMS source endpoint
- The same Terraform variable `password` is used for both the source and target databases unless you override it

## Step 9: Connect to the source EC2 instance

Use the `Source-MySQL-IP` output value:

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<SOURCE_MYSQL_IP>
```

## Step 10: Check the AWS DMS Console

After the infrastructure is created, open the AWS DMS console and confirm these resources exist:

- Replication instance: `dms-instance`
- Source endpoint: `source`
- Target endpoint: `target`
- Replication task: `replication-task-dms`

Then check the replication task status. If it does not start automatically, select `replication-task-dms` and resume or restart it from the console.

## Clean up

When you are done, destroy everything:

For IPv4:

```bash
terraform destroy -var="external_ip=$(curl -s ifconfig.me)/32"
```

For IPv6:

```bash
terraform destroy -var="external_ip=$(curl -s ifconfig.me)/128"
```

With a custom AWS profile:

```bash
terraform destroy \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=YOUR_PUBLIC_IP_CIDR"
```

## Notes

- This module is documented assuming the AWS CLI `default` profile
- If your local copy uses a different default profile in code, either update `variables.tf` or pass `aws_profile` explicitly at runtime
- This module deploys resources in `us-east-1`
- The default SSH public key path is `~/.ssh/id_rsa.pub`
- The database password is currently provided via a Terraform variable and should be treated as demo-only
- DMS, RDS, and EC2 resources can take several minutes to become ready
