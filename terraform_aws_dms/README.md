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

This module restricts SSH access to the EC2 source instance using your public IPv4 address.

```bash
curl -4 -s ifconfig.me
```

Use the returned value as `<YOUR_PUBLIC_IPV4>/32`.

Example:

```bash
203.0.113.10/32
```

## Step 6: Review the plan

```bash
terraform plan -var="external_ip=$(curl -4 -s ifconfig.me)/32"
```

With a custom AWS profile:

```bash
terraform plan \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=$(curl -4 -s ifconfig.me)/32"
```

## Step 7: Apply the infrastructure

```bash
terraform apply -var="external_ip=$(curl -4 -s ifconfig.me)/32"
```

With a custom AWS profile:

```bash
terraform apply \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=$(curl -4 -s ifconfig.me)/32"
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
- The source EC2 host also installs Python plus `mysql-connector-python` so you can verify the MySQL 8.x RDS target from that box without replacing MariaDB packages
- The same Terraform variable `password` is used for both the source and target databases unless you override it

## Step 9: Connect to the source EC2 instance

Use the `Source-MySQL-IP` output value:

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<SOURCE_MYSQL_IP>
```

## Step 10: Verify the source Sakila database on the EC2 instance

From the EC2 host, connect to the local MariaDB server and confirm the Sakila schema was loaded:

```bash
mysql -uroot -p
```

Then run:

```sql
SHOW DATABASES LIKE 'sakila';
USE sakila;
SHOW TABLES;
SELECT COUNT(*) AS actor_count FROM actor;
```

Expected result:
- The `sakila` database exists
- The schema contains many tables such as `actor`, `film`, and `customer`
- Queries return rows successfully

## Step 11: Check the AWS DMS Console

After the infrastructure is created, open the AWS DMS console and confirm these resources exist:

- Replication instance: `dms-instance`
- Source endpoint: `source`
- Target endpoint: `target`
- Replication task: `replication-task-dms`

Then check the replication task status. If it does not start automatically, select `replication-task-dms` and resume or restart it from the console.

Wait until the replication task reaches a completed or load-finished state before verifying data on the target RDS instance.

## Step 12: From the same EC2 instance, connect to the target RDS instance and verify Sakila was migrated

This EC2 instance can connect to the RDS instance on port `3306` because both resources use the same security group, and that security group allows MySQL traffic from itself. In Terraform, see:
- [main.tf](/Users/moosakhalid/aws/terraform_aws_dms/main.tf#L72)
- [main.tf](/Users/moosakhalid/aws/terraform_aws_dms/main.tf#L105)
- [main.tf](/Users/moosakhalid/aws/terraform_aws_dms/main.tf#L122)

From the EC2 host, use the installed Python connector to verify the RDS target:

```bash
python3 - <<'PY'
import mysql.connector

conn = mysql.connector.connect(
    host="<RDS_ENDPOINT_HOSTNAME>",
    user="admin",
    password="<PASSWORD>",
    database="sakila",
)

cur = conn.cursor()
cur.execute("SHOW TABLES")
print("tables:", len(cur.fetchall()))
cur.execute("SELECT COUNT(*) FROM actor")
print("actor_count:", cur.fetchone()[0])
cur.close()
conn.close()
PY
```

You can get the hostname from:

```bash
terraform output RDS-Endpoint-Hostname
```

After connecting, run:

```sql
SHOW DATABASES;
USE sakila;
SHOW TABLES;
SELECT COUNT(*) AS actor_count FROM actor;
```

Expected result after DMS finishes:
- The `sakila` schema exists on the target RDS instance
- The Sakila tables are present
- Row counts such as `actor_count` match the source closely or exactly, depending on task timing

If `sakila` is not yet present on RDS, recheck the DMS task status and endpoint health in the AWS DMS console.

## Clean up

When you are done, destroy everything:

```bash
terraform destroy -var="external_ip=$(curl -4 -s ifconfig.me)/32"
```

With a custom AWS profile:

```bash
terraform destroy \
  -var="aws_profile=YOUR_PROFILE_NAME" \
  -var="external_ip=$(curl -4 -s ifconfig.me)/32"
```

## Notes

- This module is documented assuming the AWS CLI `default` profile
- If your local copy uses a different default profile in code, either update `variables.tf` or pass `aws_profile` explicitly at runtime
- This module deploys resources in `us-east-1`
- The default SSH public key path is `~/.ssh/id_rsa.pub`
- The database password is currently provided via a Terraform variable and should be treated as demo-only
- DMS, RDS, and EC2 resources can take several minutes to become ready
- IAM propagation for the DMS service roles is delayed explicitly before the replication instance is created, because Terraform `depends_on` alone does not wait for AWS IAM eventual consistency

## Instance Type Notes

AWS instance offerings can change over time by region and Availability Zone. If `terraform apply` fails because an EC2 or DMS instance class is unavailable, update the value in the Terraform code and try again.

Current locations in this module:
- EC2 source instance type: `main.tf`
- DMS replication instance class: `dms.tf`

### EC2 instance type

If the EC2 instance fails with an error such as "instance type is not supported in your requested Availability Zone", choose another small burstable instance type and update `main.tf`.

Examples:
- `t3.micro`
- `t3a.micro`
- `t2.micro`

To check which EC2 instance types are offered in a specific Availability Zone:

```bash
aws ec2 describe-instance-type-offerings \
  --location-type availability-zone \
  --filters Name=location,Values=us-east-1a
```

To check offerings across the region:

```bash
aws ec2 describe-instance-type-offerings \
  --location-type region \
  --filters Name=location,Values=us-east-1
```

You can narrow the output to small burstable families if needed:

```bash
aws ec2 describe-instance-type-offerings \
  --location-type region \
  --filters Name=location,Values=us-east-1 \
            Name=instance-type,Values=t2.micro,t3.micro,t3a.micro
```

### DMS replication instance class

If DMS replication instance creation fails because the class is unavailable or no longer supported, update the replication instance class in `dms.tf`.

Examples of DMS classes you may need to use instead:
- `dms.t3.small`
- `dms.c5.large`

AWS DMS supported replication instance classes can change over time, so check the current AWS documentation if a class stops working.

### Practical advice

- Treat instance sizes in this repo as working defaults, not permanent values
- If AWS rejects an instance type or class, replace it with a currently supported one and rerun `terraform plan` and `terraform apply`
- Availability can differ by account, region, and Availability Zone
