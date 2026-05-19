# ------------------------------------------------------------------------------
# Create the AWS EKS Cluster
# This is the control plane for Kubernetes on AWS
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  # Full cluster name built from business + environment + cluster_name
  name = local.eks_cluster_name

  # Kubernetes version to use for the control plane
  version = var.cluster_version

  # IAM role used by EKS to manage the control plane
  role_arn = aws_iam_role.eks_cluster.arn

  # VPC configuration for control plane networking
  vpc_config {
    # Subnets where EKS control plane ENIs will be placed (should be private)
    #subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    subnet_ids = values(local.private_subnets_map)

    # Allow access to private endpoint (inside VPC)
    endpoint_private_access = var.cluster_endpoint_private_access

    # Allow access to public endpoint (from internet, controlled via CIDRs)
    endpoint_public_access = var.cluster_endpoint_public_access

    # List of CIDRs allowed to reach the public endpoint
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }

  # Define the service CIDR range used by Kubernetes services (optional)
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Enable EKS control plane logging for visibility and debugging
  enabled_cluster_log_types = [
    "api",               # API server audit logs
    "audit",             # Kubernetes audit logs
    "authenticator",     # Authenticator logs for IAM auth
    "controllerManager", # Logs for controller manager
    "scheduler"          # Logs for pod scheduling
  ]

  # Ensure IAM policy attachments complete before cluster creation
  # Helps avoid race conditions during provisioning and destroy
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  # Common tags applied to the EKS cluster
  tags = var.tags

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP" # Three options: CONFIG_MAP, API, API_AND_CONFIG_MAP
    bootstrap_cluster_creator_admin_permissions = true
  }

}

# Fetch the TLS certificate for the EKS OIDC issuer to get the thumbprint
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# NEW FOR KARPENTER - Create the IAM OIDC Provider for the cluster
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"] # MUST be exactly this for EKS
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = var.tags
}

resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "karpenter-core-infrastructure"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  # Ensure these are PRIVATE subnets
  subnet_ids = values(local.private_subnets_map)

  selector {
    namespace = "karpenter"
  }

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  tags = var.tags
}