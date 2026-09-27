output "github_deploy_role_arn" {
  description = "IAM role ARN for production GitHub Actions deployments"
  value       = aws_iam_role.github_deploy.arn
}

output "github_preview_deploy_role_arn" {
  description = "IAM role ARN for preview/test GitHub Actions deployments"
  value       = var.enable_preview_deploy_role ? aws_iam_role.github_preview_deploy[0].arn : null
}
