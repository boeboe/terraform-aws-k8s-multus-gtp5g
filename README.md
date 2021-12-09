# terraform-aws-k8s-multus-gtp5g

![Terraform Version](https://img.shields.io/badge/terraform-≥_1.0.0-blueviolet)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/boeboe/terraform-aws-k8s-multus-gtp5g?label=registry)](https://registry.terraform.io/modules/boeboe/k8s-multus-gtp5g/aws)
[![GitHub issues](https://img.shields.io/github/issues/boeboe/terraform-aws-k8s-multus-gtp5g)](https://github.com/boeboe/terraform-aws-k8s-multus-gtp5g/issues)
[![Open Source Helpers](https://www.codetriage.com/boeboe/terraform-aws-k8s-multus-gtp5g/badges/users.svg)](https://www.codetriage.com/boeboe/terraform-aws-k8s-multus-gtp5g)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

Terraform module which creates a [k8s](https://kubernetes.io/) cluster with
 - [gtp5g](https://github.com/PrinzOwO/gtp5g) kernel module installed on the master 
and worker nodes
 - [Calico](https://github.com/projectcalico/cni-plugin) CNI installed for pod networking 
 - [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) CNI installed for multi nic support
 - [AWS load balancer controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/) installed for autop creation of LB based on Ingress or Service Type LoadBalancer
 - [Rancher local path provisioner](https://hub.docker.com/r/rancher/local-path-provisioner) as default storage class for persistent volume creation 
 - A configurable amount of extra interfaces/subnets to be added to the k8s master and workers


Make sure to check the number of supported interfaces for your EC2 instance types!
 - https://aws.amazon.com/ec2/instance-types/
 - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html

## Usage

``` hcl
module "k8s-multus-gtp5g" {
  aws_region            = "eu-west-1"
  aws_availability_zone = "eu-west-1a"

  aws_extra_tags = {
    "Email" : "b.vanbos@gmail.com",
    "Environment" : "multus-demo",
    "Owner" : "Bart Van Bos",
    "Managed" : "Terraform",
  }

  aws_allowed_external_cidr_blocks = ["0.0.0.0/0"]

  aws_bastion_instance_type = "t2.medium"
  aws_master_instance_type  = "t2.large"
  aws_worker_instance_type  = "t2.large"
  aws_instance_apt_upgrade  = true

  aws_route53_isprivate = false
  aws_route53_zone      = "multus-demo.twistio.io"

  aws_vpc_cidr            = "10.0.0.0/16"
  aws_subnet_cidr_public  = "10.0.0.0/24"
  aws_subnet_cidr_private = "10.0.1.0/24"

  aws_subnets_extra = {
    "extra_second" = {
      description     = "Extra secundary interface"
      interface_index = 1
      subnet_cidr     = "10.0.2.0/24"
    },
    "extra_third" = {
      description     = "Extra third interface"
      interface_index = 2
      subnet_cidr     = "10.0.3.0/24"
    }
  }

  k8s_cluster_name  = "multus-demo"
  k8s_version       = "1.21.7"
  k8s_k9s_version   = "0.25.7"

  k8s_subnet_cidr_pod_network = "192.168.0.0/16"
  k8s_num_workers             = 2

  k8s_local_kubeconfig = "/tmp/kubeconfig.yaml"
}
```

Check the [examples](examples) for more details.

## Inputs

### Azure related configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | AWS region | string | | true |
| aws_availability_zone | AWS availability zone | string | | true |
| aws_extra_tags | A set of tags to assign to the created resources | string | | true |
| aws_allowed_external_cidr_blocks | List of CIDR blocks from which it is allowed to make bastion SSH and kubectl connections | string | | true |
| aws_bastion_instance_type | EC2 instance type for the bastion host | string | | true |
| aws_master_instance_type | EC2 instance type for the master node (must have at least 2 CPUs) | string | | true |
| aws_worker_instance_type | EC2 instance type for the worker nodes | string | | true |
| aws_instance_apt_upgrade | Perform an aptitude upgrade during cloud-init | string | | true |
| aws_route53_isprivate | Private or public route53 hosted zone | bool | | true |
| aws_route53_zone | Route53 hosted zone for the LBs | string | | true |
| aws_vpc_cidr | CIDR block for the VPC and subnet | string | | true |
| aws_subnet_cidr_public | CIDR block for the public subnet | string | | true |
| aws_subnet_cidr_private | CIDR block for the private subnet | string | | true |
| aws_subnets_extra | Extra subnets | string | | true |



### K8s related configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| k8s_cluster_name | Name for the Kubernetes cluster. If null, a random name is automatically chosen | map | | true |
| k8s_version | Kubernetes version | string | | true |
| k8s_k9s_version | K9s version | string | | true |
| k8s_subnet_cidr_pod_network | CIDR block for kubernetes pod network | string | | true |
| k8s_num_workers | Number of worker nodes | number | | true |
| k8s_local_kubeconfig | Output file for kubeconfig | string | | true |


## Outputs

| Name | Description | Type |
|------|-------------|------|
| aws_bastion_public_ip | Public ip address for ssh | string |
| aws_bastion_ssh_command | Command to access jumphost through SSH | string |
| aws_lb_dns_k8s_apiserver | Public LB DNS of Kubernetes apiserver | string |
| aws_lb_dns_k8s_ingress | Public LB DNS of Kubernetes ingress | string |
| aws_route53_zone_id | Route53 zone id for Kubernetes | string |
| aws_route53_k8s_apiserver | Route53 DNS for Kubernetes apiserver | string |
| aws_route53_k8s_ingress | Route53 DNS for Kubernetes ingress | string |
| k8s_master_private_ip | Kubernetes master private ip address | string |
| k8s_worker_primary_private_ips | Kubernetes worker private ip addresses | string |
| k8s_worker_extra_subnet_ips | Kubernetes worker extra subnet ip addresses | string |
| k8s_node_info | Kubernetes kubectl get nodes command | string |


## More information

TBC

## License

terraform-aws-k8s-multus-gtp5g is released under the **MIT License**. See the bundled [LICENSE](LICENSE) file for details.
