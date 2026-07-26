provider "aws" {
  alias  = "dev"
  region = "ap-south-2"

  assume_role {
    role_arn = var.dev_role_arn
  }
}

provider "aws" {
  alias  = "prod"
  region = "ap-south-2"

  assume_role {
    role_arn = var.prod_role_arn
  }
}