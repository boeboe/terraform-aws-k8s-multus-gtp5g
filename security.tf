resource "aws_key_pair" "ssh_key_pair" {
  key_name_prefix = "${local.name_prefix}-"
  public_key      = file(var.public_key_file)
  tags            = var.aws_extra_tags
}

resource "aws_security_group" "bastion_sg" {
  name        = "${local.name_prefix}-k8s-bastion-sg"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security group for bastion host"

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-bastion-sg"
    }
  )
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id
  description       = "${local.name_prefix}-bastion-egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id
  description       = "${local.name_prefix}-bastion-ingress-ssh"

  protocol    = "tcp"
  cidr_blocks = var.aws_allowed_external_cidr_blocks
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group" "k8s_master_sg" {
  name        = "${local.name_prefix}-k8s-master-sg"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security group for kubernetes master nodes"

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-k8s-master-sg"
    }
  )
}

resource "aws_security_group_rule" "k8s_master_egress" {
  type              = "egress"
  security_group_id = aws_security_group.k8s_master_sg.id
  description       = "${local.name_prefix}-k8s-master-egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "k8s_master_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  description       = "${local.name_prefix}-k8s-master-ingress-ssh"

  protocol    = "tcp"
  cidr_blocks = [var.aws_subnet_cidr_public]
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "k8s_master_ingress_apiserver" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  description       = "${local.name_prefix}-k8s-master-ingress-apiserver"

  protocol    = "tcp"
  cidr_blocks = var.aws_allowed_external_cidr_blocks
  from_port   = 6443
  to_port     = 6443
}

resource "aws_security_group_rule" "k8s_master_ingress_node_internal" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  description       = "${local.name_prefix}-k8s-master-ingress-node-internal"

  protocol  = -1
  self      = true
  from_port = 0
  to_port   = 0
}

resource "aws_security_group_rule" "k8s_master_ingress_pod_internal" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_master_sg.id
  description       = "${local.name_prefix}-k8s-master-ingress-pod-internal"

  protocol    = -1
  cidr_blocks = [var.k8s_subnet_cidr_pod_network]
  from_port   = 0
  to_port     = 0
}

resource "aws_security_group" "k8s_worker_sg" {
  name        = "${local.name_prefix}-k8s-worker-sg"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security group for kubernetes worker nodes"

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-k8s-worker-sg"
    }
  )
}

resource "aws_security_group_rule" "k8s_worker_egress" {
  type              = "egress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "k8s_worker_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-ingress-ssh"

  protocol    = "tcp"
  cidr_blocks = [var.aws_subnet_cidr_public]
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "k8s_worker_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-ingress-http"

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 80
  to_port     = 80
}

resource "aws_security_group_rule" "k8s_worker_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-ingress-https"

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 443
  to_port     = 443
}

resource "aws_security_group_rule" "k8s_worker_ingress_node_internal" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-ingress-node-internal"

  protocol  = -1
  self      = true
  from_port = 0
  to_port   = 0
}

resource "aws_security_group_rule" "k8s_worker_ingress_pod_internal" {
  type              = "ingress"
  security_group_id = aws_security_group.k8s_worker_sg.id
  description       = "${local.name_prefix}-k8s-worker-ingress-pod-internal"

  protocol    = -1
  cidr_blocks = [var.k8s_subnet_cidr_pod_network]
  from_port   = 0
  to_port     = 0
}

data "aws_iam_policy_document" "policy_doc_for_bastion_role" {
  statement {
    sid = "BastionAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_role" {
  name_prefix        = "${local.name_prefix}-bastion-role-"
  description        = "iam role for bastion host"
  assume_role_policy = data.aws_iam_policy_document.policy_doc_for_bastion_role.json

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-bastion-role"
    }
  )
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name_prefix = "${local.name_prefix}-bastion-instance-profile-"
  role        = aws_iam_role.bastion_role.name

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-bastion-instance-profile"
    }
  )
}

resource "aws_iam_policy" "bastion_policy" {
  name        = "${local.name_prefix}-bastion-policy"
  path        = "/"
  description = "iam policy for bastion host"
  policy      = file("${path.module}/templates/iam_policies/bastion.json")

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-bastion-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_attachment" {
  policy_arn = aws_iam_policy.bastion_policy.arn
  role       = aws_iam_role.bastion_role.name
}

data "aws_iam_policy_document" "policy_doc_for_worker_role" {
  statement {
    sid = "WorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker_role" {
  name_prefix        = "${local.name_prefix}-worker-role-"
  description        = "iam role for kubernetes worker hosts"
  assume_role_policy = data.aws_iam_policy_document.policy_doc_for_worker_role.json

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-worker-role"
    }
  )
}

resource "aws_iam_instance_profile" "worker_instance_profile" {
  name_prefix = "${local.name_prefix}-worker-instance-profile-"
  role        = aws_iam_role.worker_role.name

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-worker-instance-profile"
    }
  )
}

resource "aws_iam_policy" "worker_policy" {
  name        = "${local.name_prefix}-worker-policy"
  path        = "/"
  description = "iam policy for kubernetes worker hosts"
  policy      = file("${path.module}/templates/iam_policies/worker.json")

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-worker-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "worker_role_policy_attachment" {
  policy_arn = aws_iam_policy.worker_policy.arn
  role       = aws_iam_role.worker_role.name
}
