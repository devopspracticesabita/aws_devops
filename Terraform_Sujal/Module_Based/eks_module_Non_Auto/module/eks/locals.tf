# --------------------------------------------------------------------
# Local values used throughout the EKS configuration
# Helps enforce naming consistency and reduce duplication
# --------------------------------------------------------------------
#data "terraform_remote_state" "vpc" {
#  backend = "s3"

#  config = {
#    bucket = "tfstate-bucket-sujal-mitra"     # Name of the remote S3 bucket where the VPC state is stored
#    key    = "dev/terraform.tfstate"        # Path to the VPC tfstate file within the bucket
#    region = var.aws_region                   # Region where the S3 bucket and DynamoDB table exist
#  }
#}

locals {
  # Business division or team name (from variable)
  owners = var.business_division # Example: "retail"

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name # Example: "dev"

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}" # Example: "retail-dev"

  # Full EKS cluster name used for resource naming and tagging
  eks_cluster_name = "${local.name}-${var.cluster_name}" # Example: "retail-dev-eksdemo"

  #public_subnets_map  = data.terraform_remote_state.vpc.outputs.public_subnets_map

  #private_subnets_map = data.terraform_remote_state.vpc.outputs.private_subnets_map

  public_subnets_map  = var.public_subnets_map
  private_subnets_map = var.private_subnets_map
}