# README
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
