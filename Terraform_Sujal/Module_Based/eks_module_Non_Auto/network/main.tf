data "terraform_remote_state" "dev" {
  backend = "s3"

  config = {
    bucket = "tfstate-bucket-sujal-mitra"
    key    = "dev/terraform.tfstate"
    region = "ap-south-2"
  }
}

data "terraform_remote_state" "prod" {
  backend = "s3"

  config = {
    bucket = "tfstate-bucket-sujal-mitra"
    key    = "prod/terraform.tfstate"
    region = "ap-south-2"
  }
}

module "transit_gateway" {

  source = "../module/transit_gateway"

  providers = {
    aws.dev  = aws.dev
    aws.prod = aws.prod
  }

  prod_account_id = var.prod_account_id
  dev_vpc_id = data.terraform_remote_state.dev.outputs.vpc_id
  prod_vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
  dev_private_subnet_ids = data.terraform_remote_state.dev.outputs.private_subnet_ids
  prod_private_subnet_ids = data.terraform_remote_state.prod.outputs.private_subnet_ids
  dev_private_route_table_ids = data.terraform_remote_state.dev.outputs.private_route_table_ids
  prod_private_route_table_ids = data.terraform_remote_state.prod.outputs.private_route_table_ids
  dev_vpc_cidr = data.terraform_remote_state.dev.outputs.vpc_cidr
  prod_vpc_cidr = data.terraform_remote_state.prod.outputs.vpc_cidr
}