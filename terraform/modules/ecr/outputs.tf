# Output the repository ARNs
output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = [for name in var.repository_names : aws_ecr_repository.repo[name].arn]
}
