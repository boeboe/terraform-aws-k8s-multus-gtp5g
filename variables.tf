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

variable "aws_private_zone" {
  type        = bool
  description = "Create a private Route53 host zone."
  default     = false
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version."
}

variable "k8s_k9s_version" {
  type        = string
  description = "K9s version."
}

variable "k8s_local_kubeconfig" {
  type        = string
  description = "Kubernetes kubeconfig local file path."
}
