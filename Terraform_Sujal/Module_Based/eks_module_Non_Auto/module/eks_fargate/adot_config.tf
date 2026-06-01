resource "kubectl_manifest" "adot_config" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: adot-collector-config
  namespace: aws-otel-collector
data:
  collector.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
          http:

    processors:
      batch:

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
          receivers: [otlp]
          processors: [batch]
          exporters: [awsemf]
YAML

  depends_on = [
    helm_release.adot
  ]
}

resource "kubectl_manifest" "adot_service" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: aws-otel-collector
spec:
  selector:
    app.kubernetes.io/name: opentelemetry-collector
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
    - name: otlp-http
      port: 4318
      targetPort: 4318
YAML

  depends_on = [
    helm_release.adot
  ]
}