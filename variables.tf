variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in OWNER/REPOSITORY format"
}

variable "github_branch" {
  type        = string
  description = "Branch allowed to assume the production deployment role"
  default     = "main"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket containing the production static website"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "Production CloudFront distribution ID"
}

variable "enable_preview_deploy_role" {
  type        = bool
  description = "Create a separate GitHub Actions role for preview/test deployments"
  default     = false
}

variable "preview_deploy_role_name" {
  type        = string
  description = "IAM role name used by GitHub Actions for preview/test deployments"
  default     = "github-kleine-auszeit-preview-deploy"
}

variable "preview_github_subjects" {
  type        = set(string)
  description = "Allowed GitHub OIDC subject patterns for the preview role. Wildcards are supported, e.g. repo:croeer/homepage-astro:ref:refs/heads/*"
  default     = []
}

variable "preview_s3_bucket_names" {
  type        = set(string)
  description = "S3 buckets the preview role may deploy to"
  default     = []
}

variable "preview_cloudfront_distribution_ids" {
  type        = set(string)
  description = "CloudFront distributions the preview role may invalidate"
  default     = []
}
