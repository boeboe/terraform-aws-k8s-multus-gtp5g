locals {
  subnets_extra_per_worker_flatten = flatten([
    for worker_index in range(var.k8s_num_workers) : [
      for name, subnet_extra in var.aws_subnets_extra : {
        name            = name
        description     = subnet_extra.description
        interface_index = subnet_extra.interface_index
        subnet_cidr     = subnet_extra.subnet_cidr
        worker_index    = worker_index
      }
    ]
  ])
}

resource "aws_network_interface" "workers_nic_private_subnet" {
  count       = var.k8s_num_workers
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = [cidrhost(var.aws_subnet_cidr_private, 11 + count.index)]
  description = "Primary kubernetes interface in private subnet"

  security_groups = [
    aws_security_group.k8s.id,
  ]

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nic-private-subnet-worker${count.index}"
    }
  )
}

resource "aws_network_interface" "workers_nic_extra_subnets" {
  for_each = {
    for subnets_extra_per_worker in local.subnets_extra_per_worker_flatten : "${subnets_extra_per_worker.worker_index}.${subnets_extra_per_worker.interface_index}" => subnets_extra_per_worker
  }

  subnet_id   = lookup(aws_subnet.extra_subnets, each.value.interface_index).id
  private_ips = [cidrhost(each.value.subnet_cidr, 11 + each.value.worker_index)]
  description = each.value.description

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nic-${each.value.name}-subnet-worker${each.value.worker_index}"
    }
  )
}

data "template_file" "user_data_workers" {
  count    = var.k8s_num_workers
  template = file("${path.module}/templates/user_data/worker.sh")

  vars = {
    APT_UPGRADE       = "${var.aws_instance_apt_upgrade}"
    AVAILABILITY_ZONE = var.aws_availability_zone
    K8S_TOKEN         = local.token
    K8S_VERSION       = "${var.k8s_version}-00"
    MASTER_PRIVATE_IP = aws_instance.master.private_ip
    WORKER_INDEX      = count.index
  }
}

resource "aws_instance" "workers" {
  count                = var.k8s_num_workers
  ami                  = data.aws_ami.ubuntu.image_id
  instance_type        = var.aws_worker_instance_type
  iam_instance_profile = aws_iam_instance_profile.worker_instance_profile.name
  key_name             = aws_key_pair.ssh_key_pair.key_name
  user_data            = data.template_file.user_data_workers[count.index].rendered

  network_interface {
    network_interface_id = aws_network_interface.workers_nic_private_subnet[count.index].id
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true

    tags = merge(var.aws_extra_tags, {
      "Name" = "${local.name_prefix}-worker${count.index}-disk"
      }
    )
  }

  tags = merge(var.aws_extra_tags, {
    "Name"                                       = "${local.name_prefix}-worker${count.index}"
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    }
  )
}

resource "aws_network_interface_attachment" "workers_interface_attachment" {
  for_each = {
    for subnets_extra_per_worker in local.subnets_extra_per_worker_flatten : "${subnets_extra_per_worker.worker_index}.${subnets_extra_per_worker.interface_index}" => subnets_extra_per_worker
  }

  instance_id          = aws_instance.workers[each.value.worker_index].id
  network_interface_id = lookup(aws_network_interface.workers_nic_extra_subnets, "${each.value.worker_index}.${each.value.interface_index}").id
  device_index         = each.value.interface_index
}