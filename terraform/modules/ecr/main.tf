
# Create ECR repositories
resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_names)

  name = each.key
  tags = var.tags
  force_delete = var.force_delete
}

# Configure lifecycle policy for ECR repositories
resource "aws_ecr_lifecycle_policy" "repo" {
  for_each    = toset(var.repository_names)
  repository  = each.key
  depends_on = [ aws_ecr_repository.repo ]

  policy = jsonencode({
    rules = [{
      description  = "save 7 latest images"
      rulePriority = 1
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 7
      }
    }]
  })
}
