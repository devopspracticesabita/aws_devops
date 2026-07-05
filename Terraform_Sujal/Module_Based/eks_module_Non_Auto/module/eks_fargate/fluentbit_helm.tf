resource "helm_release" "fluentbit" {
  name             = "fluent-bit"
  namespace        = "amazon-cloudwatch"
  create_namespace = true

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"

  values = [
    <<-EOT

serviceAccount:
  create: true
  name: fluent-bit

  annotations:
    eks.amazonaws.com/role-arn: ${module.fluentbit_irsa_role.iam_role_arn}

cloudWatch:
  enabled: true

  region: ap-south-2

  logGroupName: /aws/eks/${local.name}/application

  logStreamPrefix: fluentbit-

firehose:
  enabled: false

kinesis:
  enabled: false

elasticsearch:
  enabled: false

EOT
  ]

  depends_on = [
    module.fluentbit_irsa_role,
    aws_cloudwatch_log_group.application
  ]
}