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
    aws_security_group.k8s.id,
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

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nic-${each.value.name}-subnet-master"
    }
  )
}

data "template_file" "user_data_master" {
  template = file("${path.module}/templates/user_data/master.sh")

  vars = {
    AVAILABILITY_ZONE       = var.aws_availability_zone
    CLUSTER_NAME            = local.name_prefix
    K8S_TOKEN               = local.token
    K8S_VERSION             = "${var.k8s_version}-00"
    MASTER_PRIVATE_IP       = cidrhost(var.aws_subnet_cidr_private, 10)
    SUBNET_CIDR_POD_NETWORK = var.k8s_subnet_cidr_pod_network
  }
}

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = var.aws_master_instance_type
  key_name      = aws_key_pair.ssh_key_pair.key_name
  user_data     = data.template_file.user_data_master.rendered

  network_interface {
    network_interface_id = aws_network_interface.master_nic_private_subnet.id
    device_index         = 0
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

resource "aws_network_interface_attachment" "master_interface_attachment" {
  for_each = {
    for subnets_extra in local.subnets_extra_master_flatten : "${subnets_extra.interface_index}" => subnets_extra
  }

  instance_id          = aws_instance.master.id
  network_interface_id = lookup(aws_network_interface.master_nic_extra_subnets, "${each.value.interface_index}").id
  device_index         = each.value.interface_index
}
