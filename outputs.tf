output "bastion_public_ip" {
  description = "the public ip address for ssh"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "ssh command to jumphost"
  value       = "ssh ubuntu@${aws_instance.bastion.public_ip}"
}

output "zone_id" {
  description = "private zone id for Kubernetes"
  value       = var.aws_private_zone ? join("", aws_route53_zone.zone.*.zone_id) : ""
}

output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "worker_private_ips" {
  value = aws_instance.workers.*.private_ip
}
