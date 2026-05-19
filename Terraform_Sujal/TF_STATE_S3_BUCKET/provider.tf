terraform {
  required_version = ">= 1.10.0" # Terraform CLI Version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "tfstate-bucket-sujal-mitra"
    key          = "terraform.tfstate"
    region       = "ap-south-2"
    encrypt      = true
    use_lockfile = true # Enables S3-native state locking (Terraform 1.10+)
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-2"
   # Automatically tags every resource created by this provider
  default_tags {
    tags = {
      Project     = "devops-practice"
      Environment = "TFSTATE"
      ManagedBy   = "Terraform"
    }
  }
}