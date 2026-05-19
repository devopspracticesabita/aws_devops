resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "0.35.0"
  timeout          = 900

  depends_on = [
    aws_eks_fargate_profile.karpenter,
    aws_sqs_queue_policy.karpenter_interruption
  ]

  # v0.35.x Settings
  set {
    name  = "settings.aws.clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = aws_sqs_queue.karpenter_interruption.name
  }

  # set {
  #   name  = "settings.aws.defaultInstanceProfile"
  #   value = aws_iam_instance_profile.karpenter.name
  # }

  # MANDATORY Environment Variables to stop CrashLoopBackOff
  set {
    name  = "controller.env[0].name"
    value = "CLUSTER_NAME"
  }
  set {
    name  = "controller.env[0].value"
    value = aws_eks_cluster.main.name
  }
  set {
    name  = "controller.env[1].name"
    value = "AWS_REGION"
  }
  set {
    name  = "controller.env[1].value"
    value = "ap-south-2" # <--- REPLACE with your actual region
  }

  set {
    name  = "dnsPolicy"
    value = "Default"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_controller_irsa_role.iam_role_arn
  }

  # Fargate Toleration - FIXED KEY
  set {
    name  = "controller.tolerations[0].key"
    value = "eks.amazonaws.com/compute-type"
  }
  set {
    name  = "controller.tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }
}