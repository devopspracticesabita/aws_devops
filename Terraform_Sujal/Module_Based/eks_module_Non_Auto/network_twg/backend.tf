terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-bucket-sujal-mitra"
    key            = "network/transit-gateway.tfstate"
    region         = "ap-south-2"
    encrypt        = true
    use_lockfile   = true
  }
}