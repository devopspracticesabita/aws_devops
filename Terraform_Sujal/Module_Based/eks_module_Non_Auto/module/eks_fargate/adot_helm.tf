# resource "helm_release" "adot" {
#   name       = "adot-collector"
#   namespace  = "aws-otel-collector"
#   create_namespace = true

#   repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
#   chart      = "opentelemetry-collector"

#   version = "0.100.0"

  
#   set {
#     name  = "image.repository"
#     value = "public.ecr.aws/aws-observability/aws-otel-collector"
#   }


#   set {
#     name  = "mode"
#     value = "daemonset"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.adot_irsa_role.iam_role_arn
#   }

  
#   set {
#     name  = "nodeSelector.eks\\.amazonaws\\.com/compute-type"
#     value = "ec2"
#   }

  
#   set {
#     name  = "resources.requests.cpu"
#     value = "100m"
#   }

#   set {
#     name  = "resources.requests.memory"
#     value = "128Mi"
#   }

  
#   set {
#     name  = "tolerations[0].key"
#     value = "node.kubernetes.io/not-ready"
#   }

#   set {
#     name  = "tolerations[0].operator"
#     value = "Exists"
#   }

#   set {
#     name  = "config"
#     value = <<-EOT
#       receivers:
#         otlp:
#           protocols:
#             grpc:
#             http:

#       processors:
#         batch:

#       exporters:
#         awsxray:
#         awsemf:

#       service:
#         pipelines:
#           traces:
#             receivers: [otlp]
#             processors: [batch]
#             exporters: [awsxray]
#           metrics:
#             receivers: [otlp]
#             processors: [batch]
#             exporters: [awsemf]
#   EOT
# }
 
#   depends_on = [
#     aws_eks_cluster.main,
#     module.adot_irsa_role
#   ]
# }

resource "helm_release" "adot" {
  name             = "adot-collector"
  namespace        = "aws-otel-collector"
  create_namespace = true

  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.100.0"

  values = [
    <<-EOT
mode: daemonset

image:
  repository: public.ecr.aws/aws-observability/aws-otel-collector
  tag: v0.43.0

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${module.adot_irsa_role.iam_role_arn}

nodeSelector:
  karpenter.sh/nodepool: default

resources:
  requests:
    cpu: 100m
    memory: 128Mi

tolerations:
  - key: node.kubernetes.io/not-ready
    operator: Exists

config:
  receivers:
    otlp:
      protocols:
        grpc: {}
        http: {}
    prometheus:
      config:
        scrape_configs:
          - job_name: 'kube-state-metrics'
            static_configs:
              - targets: ['kube-state-metrics.kube-system:8080']
          - job_name: 'node-exporter'
            static_configs:
              - targets: ['node-exporter-prometheus-node-exporter.kube-system:9100']

  processors:
    batch: {}

  exporters:
    awsxray:
    awsemf:

  service:
    pipelines:
      traces:
        receivers: [otlp]
        processors: [batch]
        exporters: [awsxray]
      metrics:
        receivers: [otlp, prometheus]
        processors: [batch]
        exporters: [awsemf]
EOT
  ]

  depends_on = [
    aws_eks_cluster.main,
    module.adot_irsa_role
  ]
}