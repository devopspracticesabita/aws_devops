# 1. The IAM Role for Pod Identity
resource "aws_iam_role" "this" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# 2. Data Block to fetch the latest version of the EKS Pod Identity Agent Addon
data "aws_eks_addon_version" "latest" {
  for_each           = toset(var.clusters)
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

# 3. Addon Agent (Ensures the agent exists on every target cluster) DaemonSets
resource "aws_eks_addon" "pod_identity_agent" {
  for_each      = toset(var.clusters)
  cluster_name  = each.value
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.latest[each.value].version
}

# 4. Association Resource to link the IAM Role to the Kubernetes Service Account
resource "aws_eks_pod_identity_association" "this" {
  for_each        = toset(var.clusters)
  cluster_name    = each.value
  namespace       = var.namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.this.arn

  # Ensure the agent is installed before trying to associate
  depends_on = [aws_eks_addon.pod_identity_agent]
}

# 5. Permissions Policy (Attaching S3 Read Only access)
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.this.name
}

# 6. Permissions Policy for Secrets Manager and Parameter Store
resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.role_name}-secrets-policy"
  description = "Allows EKS pods to retrieve secrets and parameters via ASCP"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*" # Update with specific ARNs for production
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*" # Update with specific ARNs for production
      }
    ]
  })
}

#7. Attach the Secrets Policy to the Pod Identity Role
resource "aws_iam_role_policy_attachment" "secrets_attach" {
  policy_arn = aws_iam_policy.secrets_policy.arn
  role       = aws_iam_role.this.name
}

#8. Create SecretProviderClass
resource "kubectl_manifest" "secret_provider_class" {
  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: catalog-db-secrets
  namespace: ${var.namespace}
spec:
  provider: aws
  parameters:
    region: "ap-south-2"
    usePodIdentity: "true"
    objects: |
      - objectName: "catalog-db-secret-3"
        objectType: "secretsmanager"
        jmesPath:
          - path: "MYSQL_USER"
            objectAlias: "MYSQL_USER"
          - path: "MYSQL_PASSWORD"
            objectAlias: "MYSQL_PASSWORD"
YAML

  validate_schema = false
  depends_on      = [aws_eks_pod_identity_association.this, var.csi_driver_status]
}

# 9. Cleaned IAM Role for the EFS Driver (Using Pod Identity Only)
resource "aws_iam_role" "efs_csi" {
  name = "${var.role_name}-efs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" } # Pod Identity Service
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

#10. Attach the required AWS Managed Policy
resource "aws_iam_role_policy_attachment" "efs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi.name
}

#11. Association: Link the EFS Driver Service Account to its IAM Role via Pod Identity
resource "aws_eks_pod_identity_association" "efs_csi" {
  for_each        = toset(var.clusters)
  cluster_name    = each.value
  namespace       = var.efs_namespace
  service_account = var.efs_service_account # Standard for this addon
  role_arn        = aws_iam_role.efs_csi.arn

  depends_on = [aws_eks_addon.pod_identity_agent]
}

#12. Schema-less EFS Managed Add-on Installation via EKS API
resource "aws_eks_addon" "efs_csi_driver" {
  for_each      = toset(var.clusters)
  cluster_name  = each.value
  addon_name    = "aws-efs-csi-driver"
  addon_version = data.aws_eks_addon_version.efs_latest[each.value].version
  preserve = true

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  depends_on = [aws_eks_pod_identity_association.efs_csi]
}

#13. Data source to fetch the latest version of the AWS Secrets Store CSI Driver
data "aws_eks_addon_version" "efs_latest" {
  for_each           = toset(var.clusters)
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

# --- Cart Application DynamoDB Permissions ---

# 1. Create a dedicated role for the Cart App
resource "aws_iam_role" "cart_app" {
  name = "${var.role_name}-cart-app" # Or use a specific var like var.cart_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# 2. Create the DynamoDB Access Policy
resource "aws_iam_policy" "cart_dynamodb" {
  name        = "${var.role_name}-cart-dynamodb"
  description = "Allows Cart app to access its DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        # Use the ARN from your DynamoDB resource
        Resource = ["arn:aws:dynamodb:ap-south-2:048408301799:table/dev-cart"]
      }
    ]
  })
}

# 3. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "cart_dynamodb_attach" {
  policy_arn = aws_iam_policy.cart_dynamodb.arn
  role       = aws_iam_role.cart_app.name
}

# 4. The Association (The Bridge)
resource "aws_eks_pod_identity_association" "cart_app" {
  for_each        = toset(var.clusters)
  cluster_name    = each.value
  namespace       = var.namespace
  service_account = var.dynamodb_service_account # Matches serviceAccountName in your YAML
  role_arn        = aws_iam_role.cart_app.arn

  depends_on = [aws_eks_addon.pod_identity_agent]
}

# 5. The Policy you provided
resource "aws_iam_policy" "app_secrets_policy" {
  name        = "AppSecretsPolicy"
  description = "Allows app to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = ["*"] # Adjust to specific secret ARNs for better security
      }
    ]
  })
}
