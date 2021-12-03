aws_region            = "eu-west-1"
aws_availability_zone = "eu-west-1a"

aws_extra_tags = {
  "Email" : "b.vanbos@gmail.com",
  "Environment" : "k8s-f5gc",
  "Owner" : "Bart Van Bos",
  "Managed" : "Terraform",
}

aws_allowed_bastion_ssh_cidr_blocks = ["0.0.0.0/0"]

aws_bastion_instance_type = "t2.medium"
aws_master_instance_type  = "m5.4xlarge"
aws_worker_instance_type  = "m5.4xlarge"
aws_instance_apt_upgrade  = false

aws_private_zone = true

aws_vpc_cidr            = "10.0.0.0/16"
aws_subnet_cidr_public  = "10.0.0.0/24"
aws_subnet_cidr_private = "10.0.1.0/24"

aws_subnets_extra = {
  "n2" = {
    description     = "N2 interface between RAN and AMF"
    interface_index = 1
    subnet_cidr     = "10.0.2.0/24"
  },
  "n3" = {
    description     = "N3 interface between RAN and UPF"
    interface_index = 2
    subnet_cidr     = "10.0.3.0/24"
  },
  "n4" = {
    description     = "N4 interface between SMF and UPF"
    interface_index = 3
    subnet_cidr     = "10.0.4.0/24"
  },
  "n6" = {
    description     = "N6 interface between UPF and DN"
    interface_index = 4
    subnet_cidr     = "10.0.6.0/24"
  },
  "n9" = {
    description     = "N9 interface between UPF and UPF"
    interface_index = 5
    subnet_cidr     = "10.0.9.0/24"
  }
}

k8s_cluster_name  = "k8s-f5gc"
k8s_version       = "1.21.7"
k8s_k9s_version   = "0.25.7"

k8s_subnet_cidr_pod_network = "192.168.0.0/16"
k8s_num_workers             = 3


