variable "private_key_file" {
  type        = string
  description = "Filename of the private key of a key pair on your local machine. This key pair will allow to connect to the bastion with SSH."
  default     = "~/.ssh/id_rsa"
}

variable "public_key_file" {
  type        = string
  description = "Filename of the public key of a key pair on your local machine. This key pair will allow to connect to the bastion with SSH."
  default     = "~/.ssh/id_rsa.pub"
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS availability zone."
}

variable "aws_vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC and subnet."
}

variable "aws_subnet_cidr_public" {
  type        = string
  description = "CIDR block for the public subnet."
}

variable "aws_subnet_cidr_private" {
  type        = string
  description = "CIDR block for the private subnet."
}

variable "aws_subnets_extra" {
  type = map(object(
    {
      description     = string
      interface_index = number
      subnet_cidr     = string
    }
  ))
  description = "Extra subnets."
}

variable "k8s_subnet_cidr_pod_network" {
  type        = string
  description = "CIDR block for kubernetes pod network."
}

variable "k8s_cluster_name" {
  type        = string
  description = "Name for the Kubernetes cluster. If null, a random name is automatically chosen."
  default     = null
}

variable "aws_allowed_external_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks from which it is allowed to make bastion SSH and kubectl connections."
}

variable "aws_bastion_instance_type" {
  type        = string
  description = "EC2 instance type for the bastion host."
}

variable "aws_master_instance_type" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs)."
}

variable "aws_worker_instance_type" {
  type        = string
  description = "EC2 instance type for the worker nodes."
}

variable "aws_instance_apt_upgrade" {
  type        = bool
  description = "Upgrade ubuntu aptitude packages if true."
}

variable "k8s_num_workers" {
  type        = number
  description = "Number of worker nodes."
}

variable "aws_extra_tags" {
  type        = map(string)
  description = "A set of tags to assign to the created resources."
  default     = {}
}

variable "aws_route53_isprivate" {
  type        = bool
  description = "Boolean indicating if the route53 zone is private."
}

variable "aws_route53_zone" {
  type        = string
  description = "Route53 hosted zone."
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version."
}

variable "k8s_k9s_version" {
  type        = string
  description = "K9s version."
}

variable "k8s_install_calico_cni" {
  type        = bool
  description = "Install Calico CNI."
}

# https://docs.projectcalico.org/manifests/calico.yaml
variable "k8s_install_calico_cni_url" {
  type        = string
  description = "URL from which to install Calico CNI."
  default     = "https://raw.githubusercontent.com/boeboe/terraform-aws-k8s-multus-gtp5g/master/templates/kubernetes/calico-cni/calico-3.21.2.yaml"
}

variable "k8s_install_aws_vpc_cni" {
  type        = bool
  description = "Install AWS VPC CNI."
}

# https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.10/config/master/aws-k8s-cni.yaml
variable "k8s_install_aws_vpc_cni_url" {
  type        = string
  description = "URL from which to install AWS VPC CNI."
  default     = "https://raw.githubusercontent.com/boeboe/terraform-aws-k8s-multus-gtp5g/master/templates/kubernetes/aws-vpc-cni/aws-vpc-1.10.yaml"
}

variable "k8s_install_multus_cni" {
  type        = bool
  description = "Install Multus CNI."
}

# https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick-plugin.yml
# https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/multus/v3.7.2-eksbuild.2/aws-k8s-multus.yaml
variable "k8s_install_multus_cni_url" {
  type        = string
  description = "URL from which to install Multus CNI."
  default     = "https://raw.githubusercontent.com/boeboe/terraform-aws-k8s-multus-gtp5g/master/templates/kubernetes/multus-cni/multus-3.7.2.yaml"
}

variable "k8s_install_whereabouts_plugin" {
  type        = bool
  description = "Install Whereabouts Network Plugin."
}

# https://github.com/k8snetworkplumbingwg/whereabouts/blob/v0.5.1/doc/crds
variable "k8s_install_whereabouts_plugin_url" {
  type        = string
  description = "URL from which to install Whereabouts Network Plugin."
  default     = "https://raw.githubusercontent.com/boeboe/terraform-aws-k8s-multus-gtp5g/master/templates/kubernetes/whereabouts-plugin/whereabouts-0.5.1.yaml"
}

variable "k8s_install_rancher_local_storage" {
  type        = bool
  description = "Install Rancher Local StorageClass."
}

# https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
variable "k8s_install_rancher_local_storage_url" {
  type        = string
  description = "URL from which to install Whereabouts Network Plugin."
  default     = "https://raw.githubusercontent.com/boeboe/terraform-aws-k8s-multus-gtp5g/master/templates/kubernetes/rancher-storage/local-path-0.0.20.yaml"
}

variable "k8s_local_kubeconfig" {
  type        = string
  description = "Kubernetes kubeconfig local file path."
}
