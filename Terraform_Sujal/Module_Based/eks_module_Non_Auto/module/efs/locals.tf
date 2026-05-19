locals {
  # Business division or team name (from variable)
  owners = var.business_division # Example: "retail"

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name # Example: "dev"

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}" # Example: "retail-dev"

  private_subnets_map = var.private_subnets_map
}