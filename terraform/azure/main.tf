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

  # uncomment the lines below and
  # following this link https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
  # for Service Principal authentication
  #subscription_id = var.azure_subscription_id
  #client_id       = var.azure_client_id
  #client_secret   = var.azure_client_secret
  #tenant_id       = var.azure_tenant_id
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
  name                = "honeypot-public-ip-${count.index}"
  location            = azurerm_resource_group.honeypot.location
  resource_group_name = azurerm_resource_group.honeypot.name
  allocation_method   = "Dynamic"
  count               = var.honeypot_nodes
}

resource "azurerm_network_interface" "honeypot" {
  name                = "honeypot-nic-${count.index}"
  location            = azurerm_resource_group.honeypot.location
  resource_group_name = azurerm_resource_group.honeypot.name
  count               = var.honeypot_nodes

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.honeypot.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.honeypot.*.id, count.index)
  }
  
  tags = {
    environment = var.azure_tag
  }
}

resource "azurerm_network_interface_security_group_association" "honeypot" {
  network_interface_id      = element(azurerm_network_interface.honeypot.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.honeypot.id
  count                     = var.honeypot_nodes
}

resource "azurerm_linux_virtual_machine" "honeypot" {
  name                  = "ubuntu-linux-vm-${count.index}"
  location              = azurerm_resource_group.honeypot.location
  resource_group_name   = azurerm_resource_group.honeypot.name
  network_interface_ids = [element(azurerm_network_interface.honeypot.*.id, count.index)]
  size                  = var.azure_image_size
  count                 = var.honeypot_nodes
  source_image_reference {
    publisher = var.azure_image_owner
    offer     = var.azure_image_offer
    sku       = var.azure_image_sku
    version   = "latest"
  }
  admin_username        = var.azure_image_user
  admin_ssh_key {
    username   = var.azure_image_user
    public_key = file("${var.azure_ssh_key_pub}")
  }  
  os_disk {
    name                 = "ubuntu-linux-vm-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = var.azure_hdd_size
  }
  tags = {
    environment = var.azure_tag
  }
}

resource "null_resource" "upload" {
  count    = var.honeypot_nodes
  triggers = {
    azure_public_ip = element(azurerm_public_ip.honeypot.*.ip_address, count.index) 
  }

  connection {
    type        = "ssh"
    user        = var.azure_image_user
    host        = element(azurerm_public_ip.honeypot.*.ip_address, count.index)
    private_key = file(var.azure_ssh_key_priv)
  }

  provisioner "file" {
    destination = "/tmp/dshield.ini"
    content     = templatefile("${path.module}/../templates/dshield_ini.tpl", {
     dshield_email  = var.dshield_email
     dshield_userid = var.dshield_userid
     dshield_apikey = var.dshield_apikey
     public_ip      = element(azurerm_public_ip.honeypot.*.ip_address, count.index)
     public_ssh     = var.honeypot_ssh_port
     private_ip     = join("/", [var.honeypot_network, "24"])
     deploy_ip      = chomp(data.http.local_ip.body)
    })
  }
  
  provisioner "file" {
    destination = "/tmp/dshield.sslca"
    content     = templatefile("${path.module}/../templates/dshield_sslca.tpl", {
     dshield_ca_country  = var.dshield_ca_country
     dshield_ca_state    = var.dshield_ca_state
     dshield_ca_city     = var.dshield_ca_city
     dshield_ca_company  = var.dshield_ca_company
     dshield_ca_depart   = var.dshield_ca_depart
    })
  }

  # upload our provisioning scripts
  provisioner "file" {
    source      = "${path.module}/../scripts/"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i.bak 's/^[#\\s]*Port 22\\s*$/Port ${var.honeypot_ssh_port}/' /etc/ssh/sshd_config",
      "sudo mv /tmp/dshield.ini /etc/",
      "sudo mv /tmp/dshield.sslca /etc/"
    ]
  }

  # install required packages
  provisioner "remote-exec" {
    script = "${path.module}/../scripts/install_reqs.sh"
  }

  # depends on at least one honeypot 
  depends_on = [ azurerm_public_ip.honeypot[0] ]
}

resource "null_resource" "install" {
  count    = var.honeypot_nodes
  triggers = {
    azure_public_ip = element(azurerm_public_ip.honeypot.*.ip_address, count.index) 
  }

  connection {
    type        = "ssh"
    user        = var.azure_image_user
    host        = element(azurerm_public_ip.honeypot.*.ip_address, count.index)
    port        = var.honeypot_ssh_port
    private_key = file(var.azure_ssh_key_priv)
  }

  # install dshield honeypot
  provisioner "remote-exec" {
    script = "${path.module}/../scripts/install_honeypot.sh"
  }

  depends_on = [null_resource.upload]
}
