data "template_file" "user_data_bastion" {
  template = file("${path.module}/templates/user_data/bastion.sh")

  vars = {
    K8S_VERSION   = "${var.k8s_version}-00"
    K9S_VERSION   = "v${var.k8s_k9s_version}"
    ISTIO_VERSION = var.k8s_istio_version
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.image_id
  associate_public_ip_address = true
  instance_type               = var.aws_bastion_instance_type
  iam_instance_profile        = aws_iam_instance_profile.bastion_instance_profile.name
  key_name                    = aws_key_pair.ssh_key_pair.key_name
  source_dest_check           = true
  subnet_id                   = aws_subnet.public_subnet.id
  user_data                   = data.template_file.user_data_bastion.rendered

  root_block_device {
    volume_type           = "standard"
    volume_size           = "20"
    delete_on_termination = true

    tags = merge(var.aws_extra_tags, {
      "Name" = "${local.name_prefix}-bastion-disk"
      }
    )
  }

  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-bastion"
    }
  )
}
