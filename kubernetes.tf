data "template_file" "install_cni" {
  template = file("${path.module}/templates/kubernetes/install_cni.sh")

  vars = {
    PRIVATE_KEY_FILE  = var.private_key_file
    BASTION_PUBLIC_IP = aws_instance.bastion.public_ip
  }
}

resource "null_resource" "install_cni" {
  provisioner "local-exec" {
    command = data.template_file.install_cni.rendered
  }
  triggers = {
    instance_ids       = join(",", [aws_instance.bastion.id, aws_instance.master.id])
    install_cni_script = sha512(data.template_file.install_cni.rendered)
  }
  depends_on = [null_resource.prepare_kubectl]
}

data "template_file" "install_storageclass" {
  template = file("${path.module}/templates/kubernetes/install_storageclass.sh")

  vars = {
    PRIVATE_KEY_FILE  = var.private_key_file
    BASTION_PUBLIC_IP = aws_instance.bastion.public_ip
  }
}

resource "null_resource" "install_storageclass" {
  provisioner "local-exec" {
    command = data.template_file.install_storageclass.rendered
  }
  triggers = {
    instance_ids       = join(",", [aws_instance.bastion.id, aws_instance.master.id])
    install_cni_script = sha512(data.template_file.install_storageclass.rendered)
  }
  depends_on = [null_resource.install_cni]
}

data "template_file" "install_aws_lb_controller" {
  template = file("${path.module}/templates/kubernetes/install_awslb.sh")

  vars = {
    PRIVATE_KEY_FILE    = var.private_key_file
    BASTION_PUBLIC_IP   = aws_instance.bastion.public_ip
    CLUSTER_NAME        = local.name_prefix
    MASTER_INSTANCE_ID  = aws_instance.master.id
    WORKER_INSTANCE_IDS = join(" ", aws_instance.workers[*].id)
    WORKERS_AZ          = var.availability_zone
  }
}

resource "null_resource" "install_aws_lb_controller" {
  provisioner "local-exec" {
    command = data.template_file.install_aws_lb_controller.rendered
  }
  triggers = {
    instance_ids       = join(",", [aws_instance.bastion.id, aws_instance.master.id])
    install_cni_script = sha512(data.template_file.install_aws_lb_controller.rendered)
  }
  depends_on = [null_resource.install_cni]
}

data "template_file" "install_istio" {
  template = file("${path.module}/templates/kubernetes/install_istio.sh")

  vars = {
    PRIVATE_KEY_FILE    = var.private_key_file
    BASTION_PUBLIC_IP   = aws_instance.bastion.public_ip
  }
}

resource "null_resource" "install_istio" {
  provisioner "local-exec" {
    command = data.template_file.install_istio.rendered
  }
  triggers = {
    instance_ids       = join(",", [aws_instance.bastion.id, aws_instance.master.id])
    install_cni_script = sha512(data.template_file.install_istio.rendered)
  }
  depends_on = [null_resource.install_aws_lb_controller]
}
