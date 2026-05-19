resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "0.35.0" # Use the latest stable version

  # Critical: Karpenter must wait for the cluster and node group to be ready
  depends_on = [aws_eks_node_group.private_nodes, aws_sqs_queue_policy.karpenter_interruption]

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "settings.interruptionQueueName"
    value = aws_sqs_queue.karpenter_interruption.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_controller_irsa_role.iam_role_arn
  }

  # Ensure the controller runs on the existing "managed" node group
  set {
    name  = "controller.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "webhook.hostNetwork"
    value = "true"
  }

  set {
    name  = "settings.featureGates.drift"
    value = "true"
  }
}