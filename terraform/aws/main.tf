terraform {
  required_providers {
    aws = {
      version = "~> 3.73.0"
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

provider "aws" {
  shared_credentials_file = var.aws_credentials
  region                  = var.aws_region
  # if using separate profiles, otherwise leave at "default" or comment out
  profile                 = var.aws_profile
}

data "http" "local_ip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu_ami" {
  owners = [var.aws_ami_owner]
  most_recent = true
  filter {
    name   = "name"
    values = [ var.aws_ami_name ]
  }
}

# switched from template_file to local_file due to: https://github.com/hashicorp/terraform/issues/24616
resource "local_file" "enable_logging" {
  content = templatefile("${path.module}/../templates/install_honeypot.tpl", {output_logging  = var.output_logging})
  filename = "${path.module}/../scripts/install_honeypot.sh"
}

# upload ssh key to provision / configure ec2
resource "aws_key_pair" "honeypot_key" {
  key_name   = "dshield_honeypot"
  public_key = file(var.aws_ssh_key_pub)
}

# Create a VPC to launch our instances into
resource "aws_vpc" "honeypot_vpc" {
  cidr_block = "${var.honeypot_network}/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "honeypot_gw" {
  vpc_id     = aws_vpc.honeypot_vpc.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "honeypot_internet" {
  route_table_id         = aws_vpc.honeypot_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.honeypot_gw.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "honeypot_subnet" {
  vpc_id                  = aws_vpc.honeypot_vpc.id
  cidr_block              = "${var.honeypot_network}/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true 
}

resource "aws_security_group" "honeypot_security_group" {
  name   = "honeypot_security_group"
  vpc_id = aws_vpc.honeypot_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "honeypot" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.aws_ec2_size
  key_name               = aws_key_pair.honeypot_key.id
  vpc_security_group_ids = [ aws_security_group.honeypot_security_group.id ]
  subnet_id              = aws_subnet.honeypot_subnet.id
  count                  = var.honeypot_nodes

  tags = {
    Name = var.aws_tag
  }
}

resource "null_resource" "upload" {
  count    = var.honeypot_nodes
  triggers = {
    ec2_public_ip = element(aws_instance.honeypot.*.public_ip, count.index) 
  }

  connection {
    type        = "ssh"
    user        = var.aws_ami_user
    host        = element(aws_instance.honeypot.*.public_ip, count.index)
    private_key = file(var.aws_ssh_key_priv)
  }

  provisioner "file" {
    destination = "/tmp/dshield.ini"
    content     = templatefile("${path.module}/../templates/dshield_ini.tpl", {
     dshield_email  = var.dshield_email
     dshield_userid = var.dshield_userid
     dshield_apikey = var.dshield_apikey
     public_ip      = element(aws_instance.honeypot.*.public_ip, count.index)
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

  depends_on = [ aws_instance.honeypot ]
}

resource "null_resource" "install" {
  count    = var.honeypot_nodes
  triggers = {
    ec2_public_ip = element(aws_instance.honeypot.*.public_ip, count.index) 
  }

  connection {
    type        = "ssh"
    user        = var.aws_ami_user
    host        = element(aws_instance.honeypot.*.public_ip, count.index)
    port        = var.honeypot_ssh_port
    private_key = file(var.aws_ssh_key_priv)
  }

  # install dshield honeypot
  provisioner "remote-exec" {
    script = "${path.module}/../scripts/install_honeypot.sh"
  }

  depends_on = [null_resource.upload]
}
