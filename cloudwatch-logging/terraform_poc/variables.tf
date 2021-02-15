variable "vm-count" {
  type    = number
  default = 1
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
