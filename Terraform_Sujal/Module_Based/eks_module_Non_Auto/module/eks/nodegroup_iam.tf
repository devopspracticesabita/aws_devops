# ------------------------------------------------------------------------------
# IAM Role for EKS Managed Node Group (EC2 Worker Nodes)
# This role will be assumed by EC2 instances launched in the node group
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodegroup_role" {
  # IAM role name following environment and division-based naming
  name = "${local.name}-eks-nodegroup-role"

  # Trust policy: allow EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  # Apply global tags (e.g., Terraform=true, Environment=dev, etc.)
  tags = var.tags
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEKSWorkerNodePolicy
# Grants basic node group access to the EKS cluster
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEKS_CNI_Policy
# Allows nodes to manage networking (ENIs) via the VPC CNI plugin
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEC2ContainerRegistryReadOnly
# Grants nodes permission to pull images from Amazon ECR
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Allows logging into nodes via Session Manager without SSH keys
resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment: AmazonEBSCSIDriverPolicy
# Allows the nodes to manage EBS volumes (required for EBS CSI Driver)
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_ebs_csi_policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Create a DynamoDB Access Policy
resource "aws_iam_policy" "eks_dynamodb_policy" {
  name        = "${local.name}-eks-dynamodb-policy"
  description = "Allows EKS nodes to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ],
        Effect   = "Allow",
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Attach the policy to your existing Node Group Role
resource "aws_iam_role_policy_attachment" "eks_dynamodb_attachment" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = aws_iam_policy.eks_dynamodb_policy.arn
}

# Create a Redis IAM Auth Policy
resource "aws_iam_policy" "eks_redis_policy" {
  name        = "${local.name}-eks-redis-policy"
  description = "Allows EKS nodes to connect to Redis using IAM authentication"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "elasticache:Connect",
        Effect = "Allow",
        # Use the ARN of the Redis User created in the Redis module
        Resource = var.redis_user_arn
      }
    ]
  })
}

# Attach the Redis policy to the Node Group Role
resource "aws_iam_role_policy_attachment" "eks_redis_attachment" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = aws_iam_policy.eks_redis_policy.arn
}
