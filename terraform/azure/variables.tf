# number of honeypot instances to deploy
variable "honeypot_nodes" {
  default = 1
}

variable "dshield_email" {
}

variable "dshield_userid" {
}

variable "dshield_apikey" {
}

# location of YOUR ssh PUBLIC key to be uploaded to AZURE
# complimentary key pair to PRIVATE key below
variable "azure_ssh_key_pub" {
  default = "~/.ssh/id_rsa.pub"
}

# location of YOUR ssh PRIVATE key to run remote-exec provisioners
# complimentary key pair to PUBLIC key above
variable "azure_ssh_key_priv" {
  default = "~/.ssh/id_rsa"
}

# Azure tenant id (global UID) for M365 tenancy
variable "azure_tenant_id" {
}

# Azure subscription id (global UID) for M365 subscription
variable "azure_subscription_id" {
}

# if using Service Principal and not `az login`
# Azure client id and client secret
variable "azure_client_id" {
}

variable "azure_client_secret" {
}

# Azure region in which instances should be deployed
variable "azure_region" {
  default = "East US"
}

# Canonical Azure OwnerId
variable "azure_image_owner" {
  default = "Canonical"
}

variable "azure_image_offer" {
  description = "Ubuntu Server"
  type        = string
  default     = "UbuntuServer"
}

variable "azure_image_sku" {
  description = "18.04 LTS"
  type        = string
  default     = "18.04-LTS"
}

variable "azure_image_user" {
  description = "Ubuntu default user"
  type        = string
  default     = "ubuntu"
}

variable "azure_image_size" {
  default = "Standard_B1ls"
}

variable "azure_hdd_size" {
  default = "Standard_LRS"
}

variable "azure_tag" {
  default = "dshield_honeypot"
}

# CIDR is declared in azurerm_virtual_network & azurerm_subnet code blocks in main.tf
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

# true or false whether cowrie should output json
# also appends logrotate policy in /etc/logrotate.d/dshield
variable "output_logging" {
  default = true
}
