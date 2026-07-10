resource "aws_ecr_repository" "ui" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true # Allows terraform destroy to work even if images exist

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256" # Or "KMS" if using a customer-managed key
  }

  tags = var.tags
}

# Automatically clean up old images to save costs
resource "aws_ecr_lifecycle_policy" "ui" {
  repository = aws_ecr_repository.ui.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}