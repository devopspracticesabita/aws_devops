# 1. Map Karpenter to AWS Infrastructure
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      amiSelectorTerms: 
        - alias: al2023@latest
      role: ${aws_iam_role.karpenter_node_role.name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.eks_cluster_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.eks_cluster_name}
  YAML

  depends_on = [helm_release.karpenter]
}

# 2. Tell Karpenter which types of instances to scale
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      limits:
        cpu: "200"
        memory: "800Gi"
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
        expireAfter: 720h
      template:
        spec:
          nodeClassRef:
            name: default
            group: karpenter.k8s.aws
            kind: EC2NodeClass
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
                - m5
                - m6i
                - c5
                - c6i
            
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values:
                - large
                - xlarge

  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}
