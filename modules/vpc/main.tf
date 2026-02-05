# VPC Configuration
resource "aws_vpc" "eks_vpc" {
    cidr_block           = var.vpc_cidr
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    enable_dns_support   = true

  tags = {
    Name = "My-EkS-VPC"
    Environment = "dev"
  }
}




# Public Subnets
resource "aws_subnet" "public_subnet" {
  count                     =  length(var.public_subnet_cidr)
  vpc_id                    = aws_vpc.eks_vpc.id
  cidr_block                = var.public_subnet_cidr[count.index]
  availability_zone         = var.availability_zones[count.index]
  map_public_ip_on_launch   = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
    tier = "public"
  }
}




# Private Subnets
resource "aws_subnet" "private_subnet" {
  count                     =  length(var.private_subnet_cidr)
  vpc_id                    = aws_vpc.eks_vpc.id
  cidr_block                = var.private_subnet_cidr[count.index]
  availability_zone         = var.availability_zones[count.index]
  map_public_ip_on_launch   = false

  tags = {
    Name = "private-subnet-${count.index + 1}"
    tier = "private"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}



# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "int-gw"
  }
}


# Elastic IPs
resource "aws_eip" "eip_nat" {
  count     = length(var.public_subnet_cidr)
  domain    = "vpc"
}



# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count             = length(var.public_subnet_cidr)
  allocation_id     = aws_eip.eip_nat[count.index].id
  subnet_id         = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}




# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

 
  tags = {
    Name = "public-route-table"
  }
}


resource "aws_route_table" "private" {
  count     = length(var.private_subnet_cidr)
  vpc_id    = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

 
  tags = {
    Name = "private-route-table-${count.index + 1}"
  }
}



# Rout Table Association
resource "aws_route_table_association" "public" {
  count             = length(var.public_subnet_cidr)
  subnet_id         = aws_subnet.public_subnet[count.index].id
  route_table_id    = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count             = length(var.private_subnet_cidr)
  subnet_id         = aws_subnet.private_subnet[count.index].id
  route_table_id    = aws_route_table.private[count.index].id
}