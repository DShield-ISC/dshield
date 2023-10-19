### For instructions on how to install `terraform`, please consult the following: [HashiCorp Terraform Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli)  

### Install `git` if not part of the default OS packages:
`sudo <OS package manager here> install git`  
(_could be apt, yum, dpkg, etc._)

### Clone this repository:
`git clone https://github.com/DShield-ISC/dshield`

### Change into the `cloud provider` automation directory of choice:
- To deploy honeypots using AWS' infrastructure: 
  - `cd dshield/terraform/aws/`

- To deploy honeypots using Microsoft Azure's infrastructure: 
  - `cd dshield/terraform/azure/`

### Adjust the required and optional variables to reflect the environment:
`<insert your editor of choice here> variables.tf `  
(_no judgement if the editor isn't `vi`_)

### Define the following **required** variables:
- **dshield_email**
- **dshield_apikey**
- **dshield_userid**
- **aws_ssh_key_pub**  _OR_ **azure_ssh_key_pub**  _depending on provider_
- **aws_ssh_key_priv** _OR_ **azure_ssh_key_priv** _depending on provider_
- **aws_credentials**       _if using **AWS**_
- **azure_tenant_id**       _if using **Azure Service Principal**_
- **azure_subscription_id** _if using **Azure Service Principal**_
- **azure_client_id**       _if using **Azure Service Principal**_
- **azure_client_secret**   _if using **Azure Service Principal**_

### Optional variables:
- **honeypot_nodes** (default: `1` *increase to scale horizontally*)
- **aws_region** (default: `us-east-1`)            _if using **AWS**_
- **aws_ec2_size** (default: `t2.micro`)           _if using **AWS**_
- **azure_region** (default: `East US`)            _if using **Azure**_
- **azure_image_size** (default: `Standard_B1ls`)  _if using **Azure**_
- **honeypot_network** (default: `10.40.0.0/16` for VPC & `10.40.0.0/24` for SG)
- **honeypot_ssh_port** (default: `12222`)
- **dshield_ca_country** (default: `US`)
- **dshield_ca_state** (default: `Florida`)
- **dshield_ca_city** (default: `Jacksonville`)
- **dshield_ca_company** (default: `DShield`)
- **dshield_ca_depart** (default: `Decoy`)

### General assumptions (**please update to reflect the appropriate locations as denoted above**):
- AWS credentials are contained in the default location: 
  - `~/.aws/credentials`

- Azure credentials are successfully validated using `az login` prior to plan/apply

- SSH credentials are contained in the default location: 
  - `~/.ssh/id_rsa`
  - `~/.ssh/id_rsa.pub`

### After completing the above items, run the following commands to begin the installation:
```terraform init; terraform plan -out=honeypot; terraform apply "honeypot"```  
**OR**  
```terraform init; terraform apply``` and type `yes` when prompted
