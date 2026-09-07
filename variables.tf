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
  description = "Branch allowed to assume the deployment role"
  default     = "main"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket containing the static website"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "CloudFront distribution ID"
}
