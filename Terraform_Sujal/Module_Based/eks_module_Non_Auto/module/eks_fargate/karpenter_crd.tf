# resource "helm_release" "karpenter_crd" {
#   name       = "karpenter-crd"
#   namespace  = "karpenter"

#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter-crd"

#   version = "1.2.0"

#   create_namespace = false
# }