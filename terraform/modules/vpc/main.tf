data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = format("%s-%s-vpc", var.component, var.env)
  }
}

#subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.default.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = format("private-subnet-%s-%s-%03d", var.component, var.env, count.index + 1)
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.default.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = format("public-subnet-%s-%s-%03d", var.component, var.env, count.index + 1)
  }
}

#internet and nat gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = format("%s-%s-igw", var.component, var.env)
  }
}

resource "aws_nat_gateway" "default" {
  count         = length(var.private_subnets)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = format("nat-%s-%s-%03d", var.component, var.env, count.index + 1)
  }
}

resource "aws_eip" "nat" {
  count  = length(var.private_subnets)
  domain = "vpc"

  tags = {
    Name = format("eip-%s-%s-%03d", var.component, var.env, count.index + 1)
  }
}

#public route
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = format("%s-%s-routing-table-public", var.component, var.env)
  }

}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

#private route
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "private" {
  count                  = length(compact(var.private_subnets))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

