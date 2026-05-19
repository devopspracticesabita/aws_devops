# Install the Secrets Store CSI Driver
resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"

  wait          = false
  wait_for_jobs = false

  # Prevents pre-install/post-install hook jobs from block-stalling the run
  disable_webhooks = true  
  #disable_openapi_validation = false

  # CONSOLIDATED CONFIGURATION MAP
  values = [
    yamlencode({
      tokenRequests = [
        { audience = "sts.amazonaws.com" },     # FIXED: Restored valid AWS EKS STS endpoint matching
        { audience = "pods.eks.amazonaws.com" } # FIXED: Restored valid Pod Identity endpoint matching
      ]
      driver = {
        tokenRequests = {
          enabled = true
        }
      }
      syncSecret = {
        enabled = true
      }
      enableSecretRotation = true

      # FIXED: Explicit Node Affinity rules to prevent scheduling on Fargate micro-VMs
      linux = {
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [{
                matchExpressions = [
                  {
                    key = "eks.amazonaws.com/compute-type"
                    operator = "NotIn"
                    values   = ["fargate"]
                  }
                ]
              }]
            }
          }
        }
      }
    })
  ]

  depends_on = [module.eks]
}

resource "kubectl_manifest" "secret_provider_class_crd" {
  yaml_body = <<YAML
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: secretproviderclasses.secrets-store.csi.x-k8s.io
spec:
  group: secrets-store.csi.x-k8s.io
  names:
    kind: SecretProviderClass
    listKind: SecretProviderClassList
    plural: secretproviderclasses
    singular: secretproviderclass
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              x-kubernetes-preserve-unknown-fields: true
YAML

  depends_on = [helm_release.csi_secrets_store]
}

# Install the AWS Provider (ASCP)
resource "helm_release" "secrets_provider_aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  wait          = false
  wait_for_jobs = false
  disable_webhooks = true # Prevents pre-install/post-install hook jobs from block-stalling the run

  values = [
    yamlencode({
      serviceAccount = {
        create = true
      }
      "secrets-store-csi-driver" = {
        install = false
      }
      # FIXED: Force the AWS Provider DaemonSet off Fargate infrastructure
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [
                {
                  key = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                }
              ]
            }]
          }
        }
      }
    })
  ]

  #depends_on = [helm_release.csi_secrets_store]
  depends_on = [kubectl_manifest.secret_provider_class_crd]
}

# Install AWS Load Balancer Controller
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  wait       = false

  set {
    name  = "clusterName"
    value = module.eks.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  # FIXED: Target the actual Pod Identity validation module name used in your setup
  depends_on = [module.pod_identity_secret_manager_ebs_csi_driver]
}

# Install Metric Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  wait          = false
  wait_for_jobs = false

  values = [
    yamlencode({
      args = [
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP"
      ]

      # CRITICAL: Prevent Fargate scheduling
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                key      = "eks.amazonaws.com/compute-type"
                operator = "NotIn"
                values   = ["fargate"]
              }]
            }]
          }
        }
      }
      # Works well if you later isolate nodepools
      nodeSelector = {
        "karpenter.sh/nodepool" = "default"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          key      = "eks.amazonaws.com/compute-type"
          operator = "Exists"
        }
      ]
    })
  ]

  depends_on = [
    module.eks  
  ]
}