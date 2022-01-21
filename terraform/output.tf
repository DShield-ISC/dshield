output "install" {
  value = <<EOF

Your DShield honeypot has been configured and should be sending logs for further investigation!!

Run the following SSH command if it's necessary to manage the honeypot:

ssh -tt -o StrictHostKeyChecking=no ${var.aws_ami_user}@${aws_instance.honeypot.public_ip} -p ${var.honeypot_ssh_port} 

EOF
}
