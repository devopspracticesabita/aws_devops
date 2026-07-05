resource "aws_cloudwatch_log_group" "node_exporter" {
  name              = "/metrics/node-exporter"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "kube_state_metrics" {
  name              = "/metrics/kube-state-metrics"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "kubernetes_cadvisor" {
  name              = "/metrics/kubernetes-cadvisor"
  retention_in_days = 30

  tags = var.tags
}