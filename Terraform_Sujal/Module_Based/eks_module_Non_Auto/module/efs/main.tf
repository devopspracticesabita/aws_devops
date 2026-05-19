# 1. Security Group for EFS Mount Targets
resource "aws_security_group" "efs" {
  name        = "${local.name}-efs-sg"
  description = "Allows EKS worker nodes to communicate with EFS mount targets"
  vpc_id      = var.vpc_id

  # Ingress: Allow NFS traffic (Port 2049) from your Karpenter node security group
  ingress {
    description     = "Allow NFS traffic from Karpenter worker nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.karpenter_node_sg_id] # Points to your Karpenter node SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 2. The Amazon EFS File System
resource "aws_efs_file_system" "main" {
  creation_token   = "${local.name}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(var.tags, {
    Name = "${local.name}-efs"
  })
}

# 3. Network Mount Targets (One per private subnet/Availability Zone)
resource "aws_efs_mount_target" "main" {
  for_each        = local.private_subnets_map # Maps directly to your subnet footprint
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}