output "begin" {
  value = <<EOF

Your DShield honeypots have been configured and should be sending logs for further investigation!!

Run the following SSH command if it's necessary to manage any honeypot:

ssh -tt -o StrictHostKeyChecking=no ${var.aws_ami_user}@HONEYPOT_IP -p ${var.honeypot_ssh_port}

EOF
}

output "honeypots" {
  value = [ for honeypot in aws_instance.honeypot : honeypot.public_ip ]
  description = "DShield Honeypot IPs"
}
