region            = "eu-west-1"
availability_zone = "eu-west-1a"

cluster_name  = "k8s-f5gc"
k8s_version   = "1.21.7"
k9s_version   = "v0.25.7"
istio_version = "1.11.3"

extra_tags = {
  "Email" : "b.vanbos@gmail.com",
  "Environment" : "k8s-f5gc",
  "Owner" : "Bart Van Bos",
  "Managed" : "Terraform",
}

vpc_cidr            = "10.0.0.0/16"
subnet_cidr_public  = "10.0.0.0/24"
subnet_cidr_private = "10.0.1.0/24"

subnets_extra = {
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


allowed_bastion_ssh_cidr_blocks = ["0.0.0.0/0"]
num_workers                     = 3

subnet_cidr_pod_network = "192.168.0.0/16"

# Make sure to check the number of supported interfaces!
# https://aws.amazon.com/ec2/instance-types/
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html

bastion_instance_type = "t2.medium"
master_instance_type  = "m5.4xlarge"
worker_instance_type  = "m5.4xlarge"

private_zone = true