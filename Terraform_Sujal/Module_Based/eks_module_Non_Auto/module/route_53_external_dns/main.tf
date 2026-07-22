# 1. Create the Private Hosted Zone linked to your VPC
resource "aws_route53_zone" "private" {
  name = "catalog.local"

  vpc {
    vpc_id = var.vpc_id
  }
}

# 2. Create the CNAME record pointing to RDS
resource "aws_route53_record" "rds_cname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.catalog.local"
  type    = "CNAME"
  ttl     = "60"
  records = [var.rds_address] # Dynamically fetches current RDS endpoint
}

# 3. The Public Hosted Zone's Information Coming From Created Domain in Route 53
data "aws_route53_zone" "public" {
  provider     = aws.management
  name         = var.public_domain_name
  private_zone = false
}

# 4. IAM Role for External-DNS (Using Pod Identity)
resource "aws_iam_role" "external_dns" {
  name = "${var.environment_name}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# 5. Policy for Route 53 Access
resource "aws_iam_policy" "external_dns" {
  name = "${var.environment_name}-external-dns-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:ChangeResourceRecordSets"]
        Effect   = "Allow"
        Resource = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.public.zone_id}",
                    "arn:aws:route53:::hostedzone/${aws_route53_zone.private.zone_id}"
        ]
      },
      {
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ex_dns_attach" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

# 5. Pod Identity Association
resource "aws_eks_pod_identity_association" "external_dns" {
  for_each        = toset(var.clusters)
  cluster_name    = each.value
  namespace       = "kube-system"
  service_account = kubernetes_service_account_v1.external_dns[each.key].metadata[0].name
  role_arn        = aws_iam_role.external_dns.arn
}

resource "kubernetes_service_account_v1" "external_dns" {
  for_each = toset(var.clusters)
  metadata {
    #name      = "external-dns-sa-${each.value}"
    name      = "external-dns"
    namespace = "kube-system"
  }
}

# Create the ClusterRole
resource "kubernetes_cluster_role_v1" "external_dns" {
  for_each = toset(var.clusters)
  metadata {
    name = "external-dns-role-${each.value}"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "nodes"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }
}

# Bind the ClusterRole to the Service Account
resource "kubernetes_cluster_role_binding_v1" "external_dns" {
  for_each = toset(var.clusters)
  metadata {
    name = "external-dns-viewer-${each.value}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.external_dns[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.external_dns[each.key].metadata[0].name
    namespace = kubernetes_service_account_v1.external_dns[each.key].metadata[0].namespace
  }
}

resource "kubernetes_deployment_v1" "external_dns" {
  for_each = toset(var.clusters)
  metadata {
    name      = "external-dns-${each.value}"
    namespace = "kube-system"
    labels = {
      app = "external-dns"
      cluster = each.value # FIXED: Label matches selector criteria to pass API validation
    }
  }
  spec {
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app     = "external-dns",
        cluster = each.value
      }
    }
    template {
      metadata {
        labels = {
          app     = "external-dns",
          cluster = each.value
        }
      }
      spec {
        #service_account_name = kubernetes_service_account_v1.external_dns[each.key].metadata[0].name
        service_account_name = "external-dns"
        toleration {
          key      = "amazonaws.com"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        container {
          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }
          env {
            name  = "AWS_STS_REGIONAL_ENDPOINTS"
            value = "regional"
          }
          name  = "external-dns"
          image = "registry.k8s.io/external-dns/external-dns:v0.15.0"
          args = [
            "--source=ingress",
            "--domain-filter=${var.public_domain_name}",
            "--domain-filter=catalog.local",
            "--provider=aws",
            "--policy=upsert-only",
            #"--aws-zone-type=public",
            "--registry=txt",
            "--txt-owner-id=${each.value}",
            "--request-timeout=60s"
          ]
        }
      }
    }
  }
}
