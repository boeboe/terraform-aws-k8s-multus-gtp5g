# terraform-azure-k3s

![Terraform Version](https://img.shields.io/badge/terraform-≥_1.0.0-blueviolet)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/boeboe/terraform-aws-k8s-multus-gtp5g?label=registry)](https://registry.terraform.io/modules/boeboe/k8s-multus-gtp5g/aws)
[![GitHub issues](https://img.shields.io/github/issues/boeboe/terraform-aws-k8s-multus-gtp5g)](https://github.com/boeboe/terraform-aws-k8s-multus-gtp5g/issues)
[![Open Source Helpers](https://www.codetriage.com/boeboe/terraform-aws-k8s-multus-gtp5g/badges/users.svg)](https://www.codetriage.com/boeboe/terraform-aws-k8s-multus-gtp5g)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

Terraform module which creates a [k3s](https://k3s.io/) cluster, with multi-server 
and labels/taints management features, on azure cloud. 

## Usage

``` hcl
module "k8s-multus-gtp5g" {
  source  = "boeboe/k8s-multus-gtp5g/aws"
  version = "0.0.1"

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

  bastion_instance_type = "t2.medium"
  master_instance_type  = "m5.4xlarge"
  worker_instance_type  = "m5.4xlarge"

  private_zone = true

}
```

Check the [examples](examples) for more details.

## Inputs

### Azure related configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| az_resource_group | The name which should be used for this resource group | string | | true |
| az_location | The Azure region where the resource group should exist | string | | true |
| az_tags | A map of tags to add to all resources | map(string) | {} | false |
| az_k3s_mysql_server_name | An Azure globally unique name of your K3S MySQL database | string | | true |
| az_k3s_mysql_admin_username | Your K3S MySQL database admin username | string | | true |
| az_k3s_mysql_admin_password | Your K3S MySQL database admin password | string | | true |
| az_allow_public_ip | Your public IP address for Azure firewall access | string | | true |


### K3s related configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| k3s_server_groups | A map of group specifications for K3S servers | map | | true |
| k3s_agent_groups | A map of group specifications for K3S agents | map | {} | false |
| k3s_version | The K3s version | string | | true |
| k3s_token | The K3s token, a shared secret used to join a server or agent to a cluster | string | | true |
| k3s_kubeconfig_output | The local file to store K3s kubeconfig | string | "/tmp/kubeconfig.yaml" | false |
| k3s_cluster_domain | The K3s Cluster Domain | string | "cluster.local" | false |
| k3s_disable_component | Do not deploy packaged components and delete any deployed components (valid items: coredns, servicelb, traefik, local-storage, metrics-server) | string | "" | false |
| k3s_flannel_backend | One of "none", "vxlan", "ipsec", "host-gw" or "wireguard" | string | "vxlan" | false |
| k3s_cluster_cidr | Network CIDR to use for pod IPs | string | "10.42.0.0/16" | false |
| k3s_service_cidr | Network CIDR to use for services IPs | string | "10.43.0.0/16" | false |
| k3s_cluster_dns | Cluster IP for coredns service. Should be in your service-cidr range | string | "10.43.0.10" | false |


## Outputs

| Name | Description | Type |
|------|-------------|------|
| k3s_server_public_ips | Public IP addresses of the K3s servers | map(string) |
| k3s_agent_public_ips | Public IP addresses of the K3s agents | map(string) |
| k3s_external_lb_ip | Public IP addresses of the K3s LBs | string |
| k3s_external_lb_fqdn | Public FQDN of the K3s LBs | string |
| k3s_kubeconfig | Location of the kubeconfig file | string |
| k3s_cluster_state | Kubectl command to the K3s node status | string |
| k3s_kubectl_alias | Kubectl alias for the K3s cluster | string |


## More information

TBC

## License

terraform-azure-k3s is released under the **MIT License**. See the bundled [LICENSE](LICENSE) file for details.
