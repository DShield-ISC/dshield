terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.91.0"
    }
    http = {
      version = ">= 2.1.0"
    }
    null = {
      version = ">= 3.1.0"
    }
    local = {
      version = ">= 2.1.0"
    }
    template = {
      version = ">= 2.2.0"
    }
  }

  required_version = "~> 1.1.4"
}

provider "azurerm" {
  features {}

  # following this link https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
  # for Service Principal authentication
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

data "http" "local_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_resource_group" "honeypot" {
  name     = "honeypot-resource-group"
  location =  var.azure_region
}

resource "azurerm_network_security_group" "honeypot" {
  name                = "honeypot-security-group"
  location            = azurerm_resource_group.honeypot.location
  resource_group_name = azurerm_resource_group.honeypot.name

  security_rule {
    name                       = "allow_all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.azure_tag
  }
}

resource "azurerm_virtual_network" "honeypot" {
  name                = "honeypot-network"
  resource_group_name = azurerm_resource_group.honeypot.name
  location            = azurerm_resource_group.honeypot.location
  address_space       = ["${var.honeypot_network}/16"]
}

resource "azurerm_subnet" "honeypot" {
  name                 = "honeypot-subnet"
  resource_group_name  = azurerm_resource_group.honeypot.name
  virtual_network_name = azurerm_virtual_network.honeypot.name
  address_prefixes     = ["${var.honeypot_network}/24"]
}

resource "azurerm_public_ip" "honeypot" {
  name                = "honeypot-public-ip"
  location            = azurerm_resource_group.honeypot.location
  resource_group_name = azurerm_resource_group.honeypot.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "honeypot" {
  name                = "honeypot-nic"
  location            = azurerm_resource_group.honeypot.location
  resource_group_name = azurerm_resource_group.honeypot.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.honeypot.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.honeypot.id
  }
  
  tags = {
    environment = var.azure_tag
  }
}

resource "azurerm_network_interface_security_group_association" "honeypot" {
  network_interface_id      = azurerm_network_interface.honeypot.id
  network_security_group_id = azurerm_network_security_group.honeypot.id
}

resource "azurerm_linux_virtual_machine" "honeypot" {
  name = "ubuntu-linux-vm"
  location = azurerm_resource_group.honeypot.location
  resource_group_name   = azurerm_resource_group.honeypot.name
  network_interface_ids = [azurerm_network_interface.honeypot.id]
  size = var.azure_image_size
  source_image_reference {
    publisher = var.azure_image_owner
    offer     = var.azure_image_offer
    sku       = var.azure_image_sku
    version   = "latest"
  }
  admin_username = var.azure_image_user
  admin_ssh_key {
    username   = var.azure_image_user
    public_key = file("${var.azure_ssh_key_pub}")
  }  
  os_disk {
    name = "ubuntu-linux-vm-osdisk"
    caching = "ReadWrite"
    storage_account_type = var.azure_hdd_size
  }
  tags = {
    environment = var.azure_tag
  }
}