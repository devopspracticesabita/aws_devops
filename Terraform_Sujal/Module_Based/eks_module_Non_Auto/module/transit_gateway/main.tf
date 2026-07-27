resource "aws_ec2_transit_gateway" "main" {
  provider = aws.dev
  description = "Retail Shared Transit Gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "retail-shared-tgw"
  }
}

resource "aws_ram_resource_share" "tgw" {
  provider = aws.dev
  name = "retail-tgw-share"
  allow_external_principals = false
}

resource "aws_ram_resource_association" "tgw" {
  provider = aws.dev
  resource_share_arn = aws_ram_resource_share.tgw.arn
  resource_arn = aws_ec2_transit_gateway.main.arn
}

resource "aws_ram_principal_association" "prod" {
  provider = aws.dev
  principal = var.prod_account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

# resource "aws_ram_resource_share_accepter" "prod" {
#   provider = aws.prod

#   share_arn = aws_ram_resource_share.tgw.arn
# }

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  provider = aws.dev
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id = var.dev_vpc_id
  subnet_ids = var.dev_private_subnet_ids

  tags = {
    Name = "dev-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  provider = aws.prod
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id = var.prod_vpc_id
  subnet_ids = var.prod_private_subnet_ids

  tags = {
    Name = "prod-attachment"
  }
}

resource "aws_route" "dev_to_prod" {
  provider = aws.dev
  for_each = toset(var.dev_private_route_table_ids)
  route_table_id = each.value
  destination_cidr_block = var.prod_vpc_cidr
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}

resource "aws_route" "prod_to_dev" {
  provider = aws.prod
  for_each = toset(var.prod_private_route_table_ids)
  route_table_id = each.value
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}