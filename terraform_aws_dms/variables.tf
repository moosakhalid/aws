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
  description = "The IPv4 or IPv6 CIDR block allowed to SSH to the simulated source MySQL EC2 instance"
  type        = string
  validation {
    condition = (
      can(cidrhost(var.external_ip, 0)) &&
      var.external_ip != "0.0.0.0/0" &&
      var.external_ip != "::/0"
    )
    error_message = "external_ip must be a valid IPv4 or IPv6 CIDR block and must not be 0.0.0.0/0 or ::/0. Example: terraform plan -var external_ip=$(curl -s ifconfig.me)/32"
  }

}

variable "private-key-file" {
  description = "Path to SSH private key file. Override the default path if at a custom location OR if it doesn't exist use 'ssh-keygen -t rsa' to generate it"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
