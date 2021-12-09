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
