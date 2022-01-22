### For instructions on how to install `terraform`, please consult the following: [HashiCorp Terraform Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli)  

### Clone this repository:
`git clone https://github.com/dlee35/dshield`

### Change into the automation directory:
`cd dshield/terraform/`

### Adjust the required and optional variables to reflect the environment:
`<insert your editor of choice here> variables.tf `  
(_no judgement if the editor isn't `vi`_)

### Define the following **required** variables:
- **dshield_email**
- **dshield_apikey**
- **dshield_userid**
- **aws_ssh_key_pub**
- **aws_ssh_key_priv**
- **aws_credentials**

### Optional variables:
- **aws_region** (default: `us-east-1`)
- **aws_ec2_size** (default: `t2.micro`)
- **honeypot_network** (default: `10.40.0.0/16` for VPC & `10.40.0.0/24` for SG)
- **honeypot_ssh_port** (default: `12222`)
- **dshield_ca_country** (default: `US`)
- **dshield_ca_state** (default: `Florida`)
- **dshield_ca_city** (default: `Jacksonville`)
- **dshield_ca_company** (default: `DShield`)
- **dshield_ca_depart** (default: `Decoy`)

### General assumptions (**please update to reflect the appropriate locations as reflected above**):
- AWS credentials are contained in the default location: 
  - `~/.aws/credentials`

- SSH credentials are contained in the default location: 
  - `~/.ssh/id_rsa`

### After completing the above items, run the following commands to begin the installation:
```terraform init; terraform plan -out=honeypot; terraform apply "honeypot"```  
**OR**  
```terraform init; terraform apply``` and type `yes` when prompted
