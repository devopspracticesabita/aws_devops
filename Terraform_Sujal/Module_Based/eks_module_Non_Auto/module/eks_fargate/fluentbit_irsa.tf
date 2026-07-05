module "fluentbit_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${local.name}-fluentbit"

  oidc_providers = {
    main = {
      provider_arn = aws_iam_openid_connect_provider.oidc.arn

      namespace_service_accounts = [
        "amazon-cloudwatch:fluent-bit"
      ]
    }
  }
}