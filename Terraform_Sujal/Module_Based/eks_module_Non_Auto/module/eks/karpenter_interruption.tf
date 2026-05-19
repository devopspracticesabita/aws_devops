# SQS Queue for Karpenter Interruption Handling
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${local.name}-karpenter-interruption"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

# EventBridge rules to send events to SQS
resource "aws_cloudwatch_event_rule" "karpenter_events" {
  for_each = {
    interruption = { description = "Spot Interruption", detail_type = "EC2 Spot Instance Interruption Warning" }
    rebalance    = { description = "Capacity Rebalance", detail_type = "EC2 Instance Rebalance Recommendation" }
    state_change = { description = "Instance State Change", detail_type = "EC2 Instance State-change Notification" }
  }

  name        = "${local.name}-karpenter-${each.key}"
  description = each.value.description
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = [each.value.detail_type]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_sqs" {
  for_each = aws_cloudwatch_event_rule.karpenter_events
  rule     = each.value.name
  arn      = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.karpenter_interruption.arn
    }]
  })
}