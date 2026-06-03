resource "aws_iam_role" "grafana" {
  name = "${local.name}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_grafana_workspace" "grafana" {
  name                = "${local.name}-grafana"
  account_access_type = "CURRENT_ACCOUNT"

  authentication_providers = ["AWS_SSO"]

  permission_type = "SERVICE_MANAGED"

  role_arn = aws_iam_role.grafana.arn

  data_sources = ["PROMETHEUS"]

  depends_on = [
    aws_prometheus_workspace.amp
  ]
}