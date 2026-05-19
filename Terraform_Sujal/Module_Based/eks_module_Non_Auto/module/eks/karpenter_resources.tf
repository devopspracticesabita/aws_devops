# Security Group for Karpenter-launched nodes
resource "aws_security_group" "karpenter_node_sg" {
  name        = "${local.name}-karpenter-node-sg"
  vpc_id      = var.vpc_id # You'll need to pass vpc_id to your module variables
  description = "Security group for nodes launched by Karpenter"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    "karpenter.sh/discovery" = local.eks_cluster_name
  })
}

# Add a tag to your cluster security group so Karpenter can find it
resource "aws_ec2_tag" "cluster_sg_tag" {
  resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = local.eks_cluster_name
}

# Don't forget to tag your Node Security Group too!
resource "aws_ec2_tag" "karpenter_sg_tag" {
  resource_id = data.terraform_remote_state.eks.outputs.node_security_group_id
  key         = "karpenter.sh/discovery"
  value       = local.eks_cluster_name
}