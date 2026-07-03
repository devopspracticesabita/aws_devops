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
          - job_name: 'kubernetes-cadvisor'
            scheme: https
            kubernetes_sd_configs:
              - role: node
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            tls_config:
              insecure_skip_verify: true
            relabel_configs:
              - action: labelmap
                regex: __meta_kubernetes_node_label_(.+)
              - target_label: __address__
                replacement: kubernetes.default.svc:443
              - source_labels: [__meta_kubernetes_node_name]
                target_label: __metrics_path__
                replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor


  processors:
    batch: {}

  exporters:
    awsxray:
    awsemf:
    prometheusremotewrite:
      endpoint: ${aws_prometheus_workspace.amp.prometheus_endpoint}api/v1/remote_write
      auth:
        authenticator: sigv4auth

  extensions:
    health_check: {}
    sigv4auth:
      region: ap-south-2
      service: aps

  service:
    extensions: [health_check, sigv4auth]

    pipelines:
      traces:
        receivers: [otlp]
        processors: [batch]
        exporters: [awsxray]
      metrics:
        receivers: [otlp, prometheus]
        processors: [batch]
        exporters: [awsemf, prometheusremotewrite]
EOT
  ]

  depends_on = [
    aws_eks_cluster.main,
    module.adot_irsa_role
  ]
}