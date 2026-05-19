# 1. Map Karpenter to AWS Infrastructure
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${aws_iam_role.karpenter_node_role.name}
      securityGroupSelectorTerms:
        - tags:
            kubernetes.io/cluster/retail-dev-eksdemodev: "owned"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.eks_cluster_name}
  YAML

  depends_on = [helm_release.karpenter]
}

# 2. Tell Karpenter which types of instances to scale
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      limits:
        cpu: "100"
        memory: "400Gi"
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64", "arm64"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values:
                - t4g
                - t3
                - m5

          disruption:
            consolidationPolicy: WhenUnderutilized
            expireAfter: 720h
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}
