resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.16"

  values = [
    <<-EOT

server:
  service:
    type: ClusterIP
  ingress:
    enabled: true
    ingressClassName: alb
    hostname: argocd.catalogservicesuj.com
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
      external-dns.alpha.kubernetes.io/hostname: argocd.catalogservicesuj.com

configs:
  params:
    server.insecure: true

EOT
  ]

  depends_on = [
    aws_eks_cluster.main
  ]
}