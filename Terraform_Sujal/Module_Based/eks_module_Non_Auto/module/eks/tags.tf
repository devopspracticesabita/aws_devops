# -------------------------------------------------------------------
# Public Subnet Tags for EKS Load Balancer Support
# -------------------------------------------------------------------
resource "aws_ec2_tag" "eks_subnet_tag_public_elb" {
  #for_each = toset(data.terraform_remote_state.vpc.outputs.public_subnet_ids)
  for_each = local.public_subnets_map
  #for_each    = toset(local.public_subnets_map)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "eks_subnet_tag_public_cluster" {
  #for_each    = toset(data.terraform_remote_state.vpc.outputs.public_subnet_ids)
  for_each = local.public_subnets_map
  #for_each    = toset(local.public_subnets_map)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

# -------------------------------------------------------------------
# Private Subnet Tags for EKS Internal LoadBalancer Support
# -------------------------------------------------------------------

resource "aws_ec2_tag" "eks_subnet_tag_private_elb" {
  #for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
  for_each = local.private_subnets_map
  #for_each    = toset(local.private_subnets_map)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "eks_subnet_tag_private_cluster" {
  #for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
  for_each = local.private_subnets_map
  #for_each    = toset(local.private_subnets_map)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

# NEW FOR KARPENTER - Tag private subnets for Karpenter discovery
resource "aws_ec2_tag" "karpenter_subnet_tag" {
  for_each    = local.private_subnets_map
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = local.eks_cluster_name
}