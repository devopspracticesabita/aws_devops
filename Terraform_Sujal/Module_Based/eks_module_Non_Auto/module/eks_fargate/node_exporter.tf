resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  namespace  = "kube-system"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  version    = "4.30.0"
  values = [<<-EOT
nodeSelector:
  karpenter.sh/nodepool: default

tolerations:
  - operator: Exists
EOT
  ]

  depends_on = [
    aws_eks_cluster.main
  ]
}