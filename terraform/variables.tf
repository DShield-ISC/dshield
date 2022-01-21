variable "dshield_email" {
}

variable "dshield_userid" {
}

variable "dshield_apikey" {
}

# location of YOUR ssh PUBLIC key to be uploaded to AWS
# complimentary key pair to PRIVATE key below
variable "aws_ssh_key_pub" {
  default = "~/.ssh/id_rsa.pub"
}

# location of YOUR ssh PRIVATE key to run remote-exec provisioners
# complimentary key pair to PUBLIC key above
variable "aws_ssh_key_priv" {
  default = "~/.ssh/id_rsa"
}

# location of AWS credentials on local machine
variable "aws_credentials" {
  default = "~/.aws/credentials"
}

# AWS region in which ec2 instances should be deployed
variable "aws_region" {
  default = "us-east-1"
}

# Canonical AWS OwnerId
variable "aws_ami_owner" {
  default = "099720109477"   
}

variable "aws_ami_name" {
  description = "Ubuntu 20.04 LTS"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "aws_ami_user" {
  description = "Ubuntu AMI default user"
  type        = string
  default     = "ubuntu"
}

variable "aws_ec2_size" {
  default = "t2.micro"
}

variable "aws_tag" {
  default = "dshield_honeypot"
}

# CIDR is declared in aws_vpc & aws_subnet code blocks in main.tf
variable "honeypot_network" {
  default = "10.40.0.0"
}

variable "honeypot_ssh_port" {
  default = "12222"
}

variable "dshield_ca_country" {
  default = "US"
}

variable "dshield_ca_state" {
  default = "Florida"
}

variable "dshield_ca_city" {
  default = "Jacksonville"
}

variable "dshield_ca_company" {
  default = "DShield"
}

variable "dshield_ca_depart" {
  default = "Decoy"
}

// # number of honeypot instances to deploy
// # eventual addition
// variable "honeypot_nodes" {
//   default = 1
// }

