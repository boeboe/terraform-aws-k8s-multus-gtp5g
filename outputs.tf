output "bastion_public_ip" {
  description = "Public ip address for ssh."
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "Command to access jumphost through SSH."
  value       = "ssh -i ${var.private_key_file} ubuntu@${aws_instance.bastion.public_ip}"
}

output "aws_lb_dns_k8s_apiserver" {
  description = "Public LB DNS of Kubernetes apiserver."
  value       = aws_lb.nlb_master.dns_name
}

output "aws_lb_dns_k8s_ingress" {
  description = "Public LB DNS of Kubernetes ingress."
  value       = aws_lb.nlb_worker_ingress.dns_name
}

output "aws_route53_zone_id" {
  description = "Route53 zone id for Kubernetes."
  value       = aws_route53_zone.my_zone.zone_id
}

output "aws_route53_k8s_apiserver" {
  description = "Route53 DNS for Kubernetes apiserver."
  value       = aws_route53_record.nlb_master_k8s_api_record.fqdn
}

output "aws_route53_k8s_ingress" {
  description = "Route53 DNS for Kubernetes ingress."
  value       = aws_route53_record.nlb_worker_www_record.fqdn
}

output "k8s_master_private_ip" {
  description = "Kubernetes master private ip address."
  value       = aws_instance.master.private_ip
}

output "k8s_worker_primary_private_ips" {
  description = "Kubernetes worker primary private ip addresses."
  value       = aws_instance.workers.*.private_ip
}

output "k8s_worker_extra_subnet_ips" {
  description = "Kubernetes worker extra subnet ip addresses."
  value       = [for v in aws_network_interface.workers_nic_extra_subnets : v.private_ip]
}

output "k8s_node_info" {
  description = "Kubernetes kubectl get nodes command."
  value       = "kubectl --kubeconfig=${var.k8s_local_kubeconfig} get nodes -o wide"
}
