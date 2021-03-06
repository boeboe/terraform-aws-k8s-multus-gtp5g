resource "aws_vpc" "my_vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-igw"
    }
  )
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.my_vpc.id

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-public-routes"
    }
  )
}

resource "aws_main_route_table_association" "main_vpc_routes" {
  vpc_id         = aws_vpc.my_vpc.id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route" "igw_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_routes.id
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.aws_subnet_cidr_public
  availability_zone = var.aws_availability_zone

  tags = merge(var.aws_extra_tags, {
    "Name"                                       = "${local.name_prefix}-public-subnet"
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/elb"                     = "1"
    }
  )
}

resource "aws_route_table_association" "route_net" {
  route_table_id = aws_route_table.public_routes.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_eip" "nat_eip" {
  vpc = true

  # Terraform does not declare an explicit dependency towards the internet gateway.
  # this can cause the internet gateway to be deleted/detached before the EIPs.
  # https://github.com/coreos/tectonic-installer/issues/1017#issuecomment-307780549
  depends_on = [aws_internet_gateway.igw]

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-nat-gw"
    }
  )
}

resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.my_vpc.id

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-private-routes"
    }
  )
}

resource "aws_route" "to_nat_gw" {
  route_table_id         = aws_route_table.private_routes.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  depends_on             = [aws_route_table.private_routes]
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.aws_subnet_cidr_private
  availability_zone = var.aws_availability_zone

  tags = merge(var.aws_extra_tags, {
    "Name"                                       = "${local.name_prefix}-private-subnet"
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
    }
  )
}

resource "aws_route_table_association" "private_routing" {
  route_table_id = aws_route_table.private_routes.id
  subnet_id      = aws_subnet.private_subnet.id
}


resource "aws_subnet" "extra_subnets" {
  for_each = {
    for subnets_extra in var.aws_subnets_extra : "${subnets_extra.interface_index}" => subnets_extra
  }

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value.subnet_cidr
  availability_zone = var.aws_availability_zone

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-${each.key}-subnet"
    }
  )
}

resource "aws_route53_zone" "my_zone" {
  name    = "${var.aws_route53_zone}."
  comment = "Hosted zone for ${local.name_prefix}"

  dynamic "vpc" {
    for_each = var.aws_route53_isprivate ? [1] : []
    content {
      vpc_id = aws_vpc.my_vpc.id
    }
  }

  tags = merge(var.aws_extra_tags, {
    "Name" = "${local.name_prefix}-route53-zone"
    }
  )
}

resource "aws_route53_record" "nlb_master_k8s_api_record" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = "k8s-api"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_lb.nlb_master.dns_name}"]
}

resource "aws_route53_record" "nlb_worker_www_record" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_lb.nlb_worker_ingress.dns_name}"]
}
