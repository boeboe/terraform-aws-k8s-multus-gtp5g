provider "aws" {
  region = var.aws_region
}

resource "random_pet" "cluster_name" {}

resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  name_prefix = var.k8s_cluster_name != null ? var.k8s_cluster_name : random_pet.cluster_name.id
  token       = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # AWS account ID of Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "template_file" "bootstrap_finish" {
  template = file("${path.module}/templates/helpers/bootstrap_finish.sh")

  vars = {
    PRIVATE_KEY_FILE   = var.private_key_file
    BASTION_PUBLIC_IP  = aws_instance.bastion.public_ip
    MASTER_PRIVATE_IP  = aws_instance.master.private_ip
    WORKER_PRIVATE_IPS = join(" ", aws_instance.workers[*].private_ip)
  }
}

resource "null_resource" "bootstrap_finish" {
  provisioner "local-exec" {
    command = data.template_file.bootstrap_finish.rendered
  }
  triggers = {
    instance_ids            = join(",", concat([aws_instance.bastion.id, aws_instance.master.id], aws_instance.workers[*].id))
    bootstrap_finish_script = sha512(data.template_file.bootstrap_finish.rendered)
  }
}

data "template_file" "prepare_kubectl" {
  template = file("${path.module}/templates/helpers/prepare_kubectl.sh")

  vars = {
    PRIVATE_KEY_FILE  = var.private_key_file
    BASTION_PUBLIC_IP = aws_instance.bastion.public_ip
    MASTER_PRIVATE_IP = aws_instance.master.private_ip
    MASTER_PUBLIC_DNS = aws_lb.nlb_master.dns_name
    KUBECONFIG_LOCAL  = var.k8s_local_kubeconfig
  }
}

resource "null_resource" "prepare_kubectl" {
  provisioner "local-exec" {
    command = data.template_file.prepare_kubectl.rendered
  }
  triggers = {
    instance_ids           = join(",", [aws_instance.bastion.id, aws_instance.master.id])
    prepare_kubectl_script = sha512(data.template_file.prepare_kubectl.rendered)
  }
  depends_on = [null_resource.bootstrap_finish]
}
