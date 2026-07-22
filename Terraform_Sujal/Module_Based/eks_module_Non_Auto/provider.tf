terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
      #version = ">= 3.0.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
    }
  }
  backend "s3" {}
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# New Aliased provider for SageMaker (ap-south-1)
provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_name]
      command     = "aws"
    }
  }
}

# This is required specifically for the kubernetes_manifest resource
provider "kubernetes" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)
  load_config_file       = false # Important: prevents looking for local ~/.kube/config
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_name]
    command     = "aws"
  }
}


provider "aws" {
  alias  = "grafana"
  region = "us-east-1"
}