# 1. Requester side (Hyderabad)
resource "aws_vpc_peering_connection" "this" {
  provider    = aws.requester
  vpc_id      = var.requestor_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_region = var.accepter_region
  auto_accept = false
  tags        = merge(var.tags, { Name = "peer-${var.pair_name}" })
}

# 2. Accepter side (Mumbai)
resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true
  tags                      = merge(var.tags, { Name = "accepter-${var.pair_name}" })
}

# 3. Routes
resource "aws_route" "req_to_acc" {
  provider                  = aws.requester
  route_table_id            = var.requestor_route_table_id
  destination_cidr_block    = var.accepter_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "acc_to_req" {
  provider                  = aws.accepter
  route_table_id            = var.accepter_route_table_id
  destination_cidr_block    = var.requestor_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
