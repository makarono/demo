# Providing a reference to our default VPC
resource "aws_default_vpc" "vpc" {
}

#data
data "aws_availability_zones" "available" {
  state = "available"
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_private_subnet_1" {
  availability_zone = element(data.aws_availability_zones.available.names, 0)
}

resource "aws_default_subnet" "default_private_subnet_2" {
  availability_zone = element(data.aws_availability_zones.available.names, 1)
}

locals {
  private_subnet_1_id = aws_default_subnet.default_private_subnet_1.id
  private_subnet_2_id = aws_default_subnet.default_private_subnet_2.id
  vpc_id              = aws_default_vpc.vpc.id
}