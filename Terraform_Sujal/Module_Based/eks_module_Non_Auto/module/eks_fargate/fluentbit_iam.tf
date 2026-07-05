resource "aws_iam_policy" "fluentbit_cloudwatch" {
  name = "${local.name}-fluentbit-cloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentbit_cloudwatch" {
  role       = module.fluentbit_irsa_role.iam_role_name
  policy_arn = aws_iam_policy.fluentbit_cloudwatch.arn
}