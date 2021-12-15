locals {
  subnets_extra_master_flatten = flatten([
    for name, subnet_extra in var.aws_subnets_extra : {
      name            = name
      description     = subnet_extra.description
      interface_index = subnet_extra.interface_index
      subnet_cidr     = subnet_extra.subnet_cidr
    }
  ])
}

resource "aws_network_interface" "master_nic_private_subnet" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = [cidrhost(var.aws_subnet_cidr_private, 10)]
  description = "Primary kubernetes interface in private subnet"

  security_groups = [
    aws_security_group.k8s_master_sg.id,
  ]

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nic-private-subnet-master"
    }
  )
}

resource "aws_network_interface" "master_nic_extra_subnets" {
  for_each = {
    for subnets_extra in local.subnets_extra_master_flatten : "${subnets_extra.interface_index}" => subnets_extra
  }

  subnet_id   = lookup(aws_subnet.extra_subnets, each.value.interface_index).id
  private_ips = [cidrhost(each.value.subnet_cidr, 10)]
  description = each.value.description

  security_groups = [
    aws_security_group.extra_subnet_sg.id,
  ]

  tags = merge(var.aws_extra_tags, {
    "Name"                             = "${local.name_prefix}-nic-${each.value.name}-subnet-master"
    "node.k8s.amazonaws.com/no_manage" = "true"
    }
  )
}

data "template_file" "user_data_master" {
  template = file("${path.module}/templates/user_data/master.sh")

  vars = {
    APT_UPGRADE             = "${var.aws_instance_apt_upgrade}"
    CLUSTER_NAME            = local.name_prefix
    K8S_TOKEN               = local.token
    K8S_VERSION             = "${var.k8s_version}-00"
    MASTER_PUBLIC_DNS       = aws_lb.nlb_master.dns_name
    SUBNET_CIDR_POD_NETWORK = var.k8s_subnet_cidr_pod_network

    INSTALL_CALICO_CNI            = "${var.k8s_install_calico_cni}"
    INSTALL_AWS_VPC_CNI           = "${var.k8s_install_aws_vpc_cni}"
    INSTALL_MULTUS_CNI            = "${var.k8s_install_multus_cni}"
    INSTALL_WHEREABOUTS_PLUGIN    = "${var.k8s_install_whereabouts_plugin}"
    INSTALL_RANCHER_LOCAL_STORAGE = "${var.k8s_install_rancher_local_storage}"

    CALICO_CNI_URL            = var.k8s_install_calico_cni_url
    AWS_VPC_CNI_URL           = var.k8s_install_aws_vpc_cni_url
    MULTUS_CNI_URL            = var.k8s_install_multus_cni_url
    WHEREABOUTS_PLUGIN_URL    = var.k8s_install_whereabouts_plugin_url
    RANCHER_LOCAL_STORAGE_URL = var.k8s_install_rancher_local_storage_url
  }
}

resource "aws_instance" "master" {
  ami                  = data.aws_ami.ubuntu.image_id
  instance_type        = var.aws_master_instance_type
  iam_instance_profile = aws_iam_instance_profile.worker_instance_profile.name
  key_name             = aws_key_pair.ssh_key_pair.key_name
  user_data            = data.template_file.user_data_master.rendered

  network_interface {
    network_interface_id = aws_network_interface.master_nic_private_subnet.id
    device_index         = 0
  }

  dynamic "network_interface" {
    for_each = {
      for subnets_extra in local.subnets_extra_master_flatten : "${subnets_extra.interface_index}" => subnets_extra
    }
    content {
      network_interface_id = lookup(aws_network_interface.master_nic_extra_subnets, "${network_interface.value.interface_index}").id
      device_index         = network_interface.value.interface_index
    }
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true

    tags = merge(var.aws_extra_tags, {
      "Name" = "${local.name_prefix}-master-disk"
      }
    )
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-master"
    }
  )
}
