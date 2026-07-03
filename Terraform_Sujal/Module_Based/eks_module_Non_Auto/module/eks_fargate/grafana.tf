data "aws_caller_identity" "current" {}

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

resource "aws_iam_policy" "grafana_sns_publish" {
  name = "${local.name}-grafana-sns-publish"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:your-topic-name"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_sns" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_sns_publish.arn
}

resource "aws_iam_role_policy_attachment" "grafana_xray" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}


resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_grafana_workspace" "grafana" {
  provider = aws.grafana
  name                = "${local.name}-grafana-workspace"
  account_access_type = "CURRENT_ACCOUNT"

  authentication_providers = ["AWS_SSO"]

  permission_type = "SERVICE_MANAGED"

  role_arn = aws_iam_role.grafana.arn

  data_sources = ["PROMETHEUS", "CLOUDWATCH", "XRAY"]

  depends_on = [
    aws_prometheus_workspace.amp,
    aws_iam_role_policy_attachment.grafana_amp
  ]
}


resource "aws_grafana_role_association" "admins" {
  provider = aws.grafana
  workspace_id = aws_grafana_workspace.grafana.id

  role = "ADMIN"

  group_ids = [
    "d42834b8-30a1-70e2-85e7-632255dbd564"
  ]
}