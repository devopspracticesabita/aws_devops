# 1. Define the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
  lifecycle {
    prevent_destroy = false
  }
}

# 2. Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.environment_name}-igw" })
}

# 3. Create public Subnets
resource "aws_subnet" "public_subnet" {
  for_each                = { for idx, az in local.azs : az => local.public_subnets[idx] }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.environment_name}-public-${each.key}"})
}

# 4. Create Private Subnets
resource "aws_subnet" "private_subnet" {
  for_each          = { for idx, az in local.azs : az => local.private_subnets[idx] }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags              = merge(var.tags, { Name = "${var.environment_name}-private-${each.key}"})
  
  # Ensure public IPs are NOT assigned by default
  map_public_ip_on_launch = false 
}

# 5. Elastic IP creation for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc" # Modern replacement for 'vpc = true'
  tags = merge(var.tags, { Name = "${var.environment_name}-nat-eip" })
}

# 6.Create a shared NAT gateway for all three Private Subnet
resource "aws_nat_gateway" "nat" {
  #for_each      = aws_subnet.public_subnet
  #allocation_id = aws_eip.nat_eip[each.key].id
  #subnet_id     = each.value.id # MUST be a public subnet
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[keys(aws_subnet.public_subnet)[0]].id # MUST be a public subnet
  tags          = merge(var.tags, { Name = "${var.environment_name}-nat" })
  depends_on    = [ aws_internet_gateway.igw ]
}

# 7. Create a Route Table and Associate it
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "${var.environment_name}-public-rt" })
}

# 8. Associate Public Subnets with the Public Route Table
resource "aws_route_table_association" "public_rt_assoc" {
  for_each = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# 9. Create a Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  #for_each = aws_nat_gateway.nat
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(var.tags, { Name = "${var.environment_name}-private-rt" })
}

# 10. Associate Private Subnets with the Private Route Table
resource "aws_route_table_association" "private_rt_assoc" {
  for_each = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}