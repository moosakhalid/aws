variable "aws_profile" {
  type    = string
  default = "default"
}

variable "password" {
  description = "password to set for both databases - source & target, ideally should be fetched via Vault"
  type        = string
  default     = "lbistech123"
  sensitive   = true
}

variable "external_ip" {
  description = "The IP which we want to allow to access the simulated source MySQL hosted on EC2"
  type        = string
  validation {
    condition     = can(var.external_ip) && can(regex("[^0.0.0.0/0]", var.external_ip))
    error_message = "External IP should not be 0.0.0.0/0. Please change or set the default external_ip variable in variables.tf to your public IP - or do something like 'terraform plan|apply -var external_ip=$(curl -s ifconfig.me)/32'."
  }

}

variable "private-key-file" {
  description = "Path to SSH private key file. Override the default path if at a custom location OR if it doesn't exist use 'ssh-keygen -t rsa' to generate it"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
