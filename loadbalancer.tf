resource "aws_lb" "nlb_master" {
  name               = "${local.name_prefix}-nlb-master"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]

  enable_deletion_protection = false

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-master"
    }
  )
}

resource "aws_lb_target_group" "nlb_target_group_master" {
  name        = "${local.name_prefix}-nlb-tg-master"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    enabled  = true
    protocol = "TCP"
    interval = 10
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-tg-master"
    }
  )
}

resource "aws_lb_listener" "nlb_listener_master" {
  load_balancer_arn = aws_lb.nlb_master.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group_master.arn
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-listener-master"
    }
  )
}

resource "aws_lb" "nlb_worker_http" {
  name               = "${local.name_prefix}-nlb-worker-http"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]

  enable_deletion_protection = false

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-worker-http"
    }
  )
}

resource "aws_lb_target_group" "nlb_target_group_worker_http" {
  name        = "${local.name_prefix}-nlb-tg-worker-http"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    enabled  = true
    protocol = "TCP"
    interval = 10
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-tg-worker-http"
    }
  )
}

resource "aws_lb_listener" "nlb_listener_worker_http" {
  load_balancer_arn = aws_lb.nlb_worker_http.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group_worker_http.arn
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-listener-worker-http"
    }
  )
}

resource "aws_lb" "nlb_worker_https" {
  name               = "${local.name_prefix}-nlb-worker-https"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]

  enable_deletion_protection = false

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-worker-https"
    }
  )
}

resource "aws_lb_target_group" "nlb_target_group_worker_https" {
  name        = "${local.name_prefix}-nlb-tg-worker-https"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    enabled  = true
    protocol = "TCP"
    interval = 10
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-tg-worker-https"
    }
  )
}

resource "aws_lb_listener" "nlb_listener_worker_https" {
  load_balancer_arn = aws_lb.nlb_worker_https.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group_worker_https.arn
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nlb-listener-worker-https"
    }
  )
}

resource "aws_lb_target_group_attachment" "nlb_target_group_attach_master" {
  target_group_arn = aws_lb_target_group.nlb_target_group_master.arn
  target_id        = aws_instance.master.id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "nlb_target_group_attach_worker_http" {
  count            = var.k8s_num_workers
  target_group_arn = aws_lb_target_group.nlb_target_group_worker_http.arn
  target_id        = aws_instance.workers[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "nlb_target_group_attach_worker_https" {
  count            = var.k8s_num_workers
  target_group_arn = aws_lb_target_group.nlb_target_group_worker_https.arn
  target_id        = aws_instance.workers[count.index].id
  port             = 443
}
