resource "aws_prometheus_workspace" "amp" {
  alias = "${local.name}-amp"
}