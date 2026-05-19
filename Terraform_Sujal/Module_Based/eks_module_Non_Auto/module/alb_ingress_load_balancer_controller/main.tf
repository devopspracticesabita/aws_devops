# IAM Role with Pod Identity Trust Policy
resource "aws_iam_role" "lbc" {
  name = "${var.role_name}-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# Attach the standard LBC Policy
resource "aws_iam_policy" "lbc" {
  name = "${var.role_name}-lbc-policy"
  #policy = var.lbc_policy_json # Pass this from root or use a local file
  policy = data.http.lbc_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "lbc_attach" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}

# Pod Identity Association
resource "aws_eks_pod_identity_association" "lbc" {
  for_each        = toset(var.clusters)
  cluster_name    = each.value
  namespace       = var.alb_ingress_namespace
  service_account = var.alb_ingress_service_account
  role_arn        = aws_iam_role.lbc.arn
}