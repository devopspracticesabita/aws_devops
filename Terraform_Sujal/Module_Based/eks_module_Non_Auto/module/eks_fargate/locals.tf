locals {
  # Business division or team name (from variable)
  owners = var.business_division # Example: "retail"

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name # Example: "dev"

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}" # Example: "retail-dev"

  # Full EKS cluster name used for resource naming and tagging
  eks_cluster_name = "${local.name}-${var.cluster_name}" # Example: "retail-dev-eksdemo"

  public_subnets_map  = var.public_subnets_map
  private_subnets_map = var.private_subnets_map
}