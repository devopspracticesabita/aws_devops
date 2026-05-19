variable "requestor_vpc_id" {
}

variable "accepter_vpc_id" {
}

variable "accepter_region" {
}

variable "requestor_route_table_id" {
}

variable "accepter_route_table_id" {
}

variable "requestor_cidr" {
}

variable "accepter_cidr" {
}

variable "pair_name" {
}

variable "tags" {
  type = map(string)
}
