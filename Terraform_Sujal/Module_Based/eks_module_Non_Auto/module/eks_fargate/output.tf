# ------------------------------------------------------------------------------
# Output the EKS Cluster API server endpoint
# Used by kubectl and external tools to communicate with the cluster
# ------------------------------------------------------------------------------
output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS API server endpoint"
}

# ------------------------------------------------------------------------------
# Output the EKS Cluster ID
# Used in AWS CLI commands and automation scripts to reference the EKS cluster
# ------------------------------------------------------------------------------
output "eks_cluster_id" {
  description = "The name/id of the EKS cluster."
  value       = aws_eks_cluster.main.id
}

# ------------------------------------------------------------------------------
# Output the EKS Cluster Version
# Helpful for students to use this version in other EKS projects 
# to find supported EKS Addons based on EKS cluster version
# ------------------------------------------------------------------------------
output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = aws_eks_cluster.main.version
}

# ------------------------------------------------------------------------------
# Output the name of the EKS cluster
# Helpful for scripting, `aws eks update-kubeconfig`, etc.
# ------------------------------------------------------------------------------
output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}


# ------------------------------------------------------------------------------
# Output the EKS Cluster Certificate Authority data
# Needed when setting up kubeconfig or accessing EKS via API
# ------------------------------------------------------------------------------
output "eks_cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Base64 encoded CA certificate for kubectl config"
}

# ------------------------------------------------------------------------------
# Output command to configure kubectl for this EKS cluster
# Helpful for students to run directly after apply
# ------------------------------------------------------------------------------
output "to_configure_kubectl" {
  description = "Command to update local kubeconfig to connect to the EKS cluster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${local.eks_cluster_name}"
}

output "eks_name" {
  value = local.eks_cluster_name
}

output "eks_cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# Output the IAM Role ARN used by Karpenter Nodes
output "karpenter_node_role_arn" {
  value       = aws_iam_role.karpenter_node_role.arn
  description = "IAM Role ARN used by EC2 worker nodes launched by Karpenter"
}

# Output the Karpenter Controller IRSA Role ARN
output "karpenter_controller_role_arn" {
  value       = module.karpenter_controller_irsa_role.iam_role_arn
  description = "IAM Role ARN for the Karpenter controller pod"
}

output "karpenter_node_sg_id" {
  description = "The security group ID attached to all EC2 worker instances managed by Karpenter"
  value       = aws_security_group.karpenter_node_sg.id
}
