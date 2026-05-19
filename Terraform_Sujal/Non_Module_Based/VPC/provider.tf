terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0" 
    }
  }
  backend "s3" {
    bucket         = "tfstate-bucket-sujal-mitra"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-2"
    encrypt        = true
    # Optional: Use native S3 locking (Terraform 1.10+)
    use_lockfile   = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  #default_tags {
  #  tags = {
  #    Project     = "devops-practice"
  #    Environment = var.environment_name
  #    ManagedBy   = "Terraform"
  #  }
  }