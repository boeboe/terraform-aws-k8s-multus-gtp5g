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

variable "region" {
  type        = string
  description = "AWS region."
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC and subnet."
}

variable "subnet_cidr_public" {
  type        = string
  description = "CIDR block for the public subnet."
}

variable "subnet_cidr_private" {
  type        = string
  description = "CIDR block for the private subnet."
}

variable "subnets_extra" {
  type        = map(object(
    {
      description     = string
      interface_index = number
      subnet_cidr     = string
    }
  ))
  description = "Extra subnets."
}

variable "subnet_cidr_pod_network" {
  type        = string
  description = "CIDR block for kubernetes pod network."
}

variable "cluster_name" {
  type        = string
  description = "Name for the Kubernetes cluster. If null, a random name is automatically chosen."
  default     = null
}

variable "allowed_bastion_ssh_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks from which it is allowed to make SSH connections to the bastion host."
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for the bastion host."
}

variable "master_instance_type" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs)."
}

variable "worker_instance_type" {
  type        = string
  description = "EC2 instance type for the worker nodes."
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes."
}

variable "extra_tags" {
  type        = map(string)
  description = "A set of tags to assign to the created resources."
  default     = {}
}

variable "private_zone" {
  type        = bool
  description = "Create a private Route53 host zone."
  default     = false
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version."
}

variable "k9s_version" {
  type        = string
  description = "K9s version."
}

variable "istio_version" {
  type        = string
  description = "Istio version."
}
