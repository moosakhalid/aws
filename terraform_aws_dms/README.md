# Instructions


## DMS = Database Migration Service(AWS)

1) Creates an EC2 instance and bootstraps MariaDB on it and also makes a new user for DMS replication instance to use. 
   A sample DB known as Sakila DB is also downloaded and ingested into MariaDB.

2) An RDS DB instance is created.

3) A Security Group to be attached to appropriate resources for MySQL traffic.

4) A replication source and target endpoint for DMS

5) DMS roles

6) DMS replication instance

7) DMS replication task

### Note: By default the Terraform Deployment will look for AWS CLI profile 'linuxacademy-test' a profile that I used while testing, change it in the main.tf file under aws provider to map to your AWS CLI profile. Cheers!

It will create all resources in the us-east-1 region for simplicity but ideally since we'll be using Public IP to connect to EC2 MySQL, it could be hosted anywhere as long as it's accessible over the internet/VPN etc.

It takes a little time to run as it's creating time consuming resources like EC2 and RDS and DMS replication instances but once it completes head over to the DMS dashboard, go to the Replication task and "Resume/Restart" it.

There are a couple of bugs associated with DMS resources in Terraform which I've tried to workaround but they may still hit during deployment:

1. https://github.com/hashicorp/terraform-provider-aws/issues/11025
2. https://github.com/hashicorp/terraform-provider-aws/issues/7600

## The Terraform template assumes that you have run the "ssh-keygen -t rsa" command OR that the "~/.ssh/id_rsa" file exists, if neither of this is true, Terraform execution will fail at either validation or plan.This is done so you can ssh into the EC2 MySQL instance, and from that EC2 MySQL instance you can even connect to the RDS instance.
