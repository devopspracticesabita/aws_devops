# ------------------------------------------------------------------------------
# IAM Role for Karpenter Controller (IRSA)
# ------------------------------------------------------------------------------
module "karpenter_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                          = "${local.name}-karpenter-controller"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = aws_eks_cluster.main.name

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.oidc.arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

# ------------------------------------------------------------------------------
# IAM Role for Nodes launched by Karpenter
# ------------------------------------------------------------------------------
resource "aws_iam_role" "karpenter_node_role" {
  name = "${local.name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value
}