# ------------------------------------------------------------------------------
# 1. IAM Role for Karpenter Controller (IRSA)
# This allows the Karpenter pod (on Fargate) to provision EC2 instances
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
# 2. IAM Role for Nodes launched by Karpenter
# This is the "Instance Profile" role for the worker nodes themselves
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

# Standard EKS Worker Node Policies
resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ])
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value
}

# ------------------------------------------------------------------------------
# 3. Application Specific Policies (Moved from nodegroup_iam.tf)
# ------------------------------------------------------------------------------

# DynamoDB Access
resource "aws_iam_policy" "eks_dynamodb_policy" {
  name        = "${local.name}-eks-dynamodb-policy"
  description = "Allows Karpenter nodes to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem",
        "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"
      ],
      Effect   = "Allow",
      Resource = var.dynamodb_table_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_dynamodb_attachment" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.eks_dynamodb_policy.arn
}

# Redis (ElastiCache) IAM Auth
resource "aws_iam_policy" "eks_redis_policy" {
  name        = "${local.name}-eks-redis-policy"
  description = "Allows Karpenter nodes to connect to Redis using IAM"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "elasticache:Connect",
      Effect   = "Allow",
      Resource = var.redis_user_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_redis_attachment" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.eks_redis_policy.arn
}

# ------------------------------------------------------------------------------
# 4. Fargate Pod Execution Role (For the Karpenter Controller)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "fargate_pod_execution" {
  name = "${local.name}-fargate-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution.name
}

# Allows Karpenter nodes to join the cluster
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.karpenter_node_role.arn
  type          = "EC2_LINUX"
}

# Inline policy to grant Karpenter permissions to manage instance profiles dynamically
resource "aws_iam_role_policy" "karpenter_instance_profile_generation" {
  name = "${local.name}-karpenter-instance-profile-mgmt"
  role = module.karpenter_controller_irsa_role.iam_role_name # Hooks directly onto your controller role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:TagInstanceProfile"
        ]
        # Restrict to profiles matching your cluster prefix for security
        Resource = "arn:aws:iam::048408301799:instance-profile/${local.name}-*"
      }
    ]
  })
}

# Inline policy to grant Karpenter controller permissions to launch EC2 instances
resource "aws_iam_role_policy" "karpenter_ec2_provisioning" {
  name = "${local.name}-karpenter-ec2-provisioning"
  role = module.karpenter_controller_irsa_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.karpenter_node_role.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      }
    ]
  })
}
