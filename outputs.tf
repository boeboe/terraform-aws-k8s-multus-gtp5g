output "bastion_public_ip" {
  description = "Public ip address for ssh."
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "Command to access jumphost through SSH."
  value       = "ssh -i ${var.private_key_file} ubuntu@${aws_instance.bastion.public_ip}"
}

output "aws_zone_id" {
  description = "Private zone id for Kubernetes."
  value       = var.aws_private_zone ? join("", aws_route53_zone.zone.*.zone_id) : ""
}

output "k8s_master_private_ip" {
  description = "Kubernetes master private ip address."
  value       = aws_instance.master.private_ip
}

output "k8s_worker_private_ips" {
  description = "Kubernetes worker private ip addresses."
  value       = aws_instance.workers.*.private_ip
}

output "k8s_node_info" {
  description = "Kubernetes kubectl get nodes command."
  value       = "kubectl --kubeconfig=${var.k8s_local_kubeconfig} get nodes -o wide"
}
