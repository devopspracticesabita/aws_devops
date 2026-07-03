resource "aws_iam_policy" "adot_amp" {
  name = "${local.name}-adot-amp"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "aps:RemoteWrite"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "adot_amp" {
  role       = module.adot_irsa_role.iam_role_name
  policy_arn = aws_iam_policy.adot_amp.arn
}

module "adot_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${local.name}-adot-collector"

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.oidc.arn
      namespace_service_accounts = ["aws-otel-collector:adot-collector-opentelemetry-collector"]
    }
  }
}

# Attach policies
resource "aws_iam_role_policy_attachment" "adot_xray" {
  role       = module.adot_irsa_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "adot_cloudwatch" {
  role       = module.adot_irsa_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}