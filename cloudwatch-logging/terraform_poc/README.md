# README
### To run:
1. Clone repo, cd into this directory
  a. optional step, generate SSH keypair if required, as its needed when spinning up VM
     ```
     ssh-keygen -t rsa
     ```
     
     The code assumes default location for SSH key pair files i.e. under `/home/<user>/.ssh/`
     
2. terraform init; terraform plan;terraform apply

### Some assumptions(IMPORTANT - Please read):
1. The AWS user / role running this Terraform code should have appropriate permissions to spin up network components
   like VPCs, SGs, Route tables, Subnets, compute resource EC2, IAM policy and roles and the iam:PassRole permission.
   
2. This script assumes that SSH key pairs are already deployed, default values for files are in `variables.tf`,
   if the keys don't exist your deployment will fail. They are needed to connect and bootstrap stuff on EC2 using 
   Terraform provisioners.
   
   
---
## Proof-of-Concept of CloudWatch agent custom config and metrics logging using
## Terraform

---

## WARNING in main.tf Security Group allows all incoming
## traffic on port 22, change the CIDR block accordingly
## I'll try to automate the `curl ifconfig.me` command to
## inject Terraform machines IP in there later. 

---

### Random notes

### Template file function syntax and escaping ${ in Terraform
templatefile("amazon-cloudwatch-agent.tpl", {region = "us-east-1"})

to escapte ${ in json use $${ in template file being rendered



## Ideas for later
1. Auto plug in your local machines public IP into SG's SSH ingress rule.
2. Auto generate SSH Keypairs using Terraform built-in functions.
