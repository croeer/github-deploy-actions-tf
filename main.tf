data "aws_caller_identity" "current" {}

#
# GitHub Actions OIDC Provider
#
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "GitHub Actions"
  }
}

#
# Production trust policy:
# ONLY this repository, ONLY pushes/runs for the configured production branch
#
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name = "github-kleine-auszeit-deploy"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  max_session_duration = 3600

  tags = {
    Name = "GitHub Kleine Auszeit Deploy"
  }
}

#
# Production permissions required by:
#
# aws s3 sync ./dist s3://bucket --delete
# aws cloudfront create-invalidation ...
#
data "aws_iam_policy_document" "github_deploy" {

  statement {
    sid    = "ListWebsiteBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}"
    ]
  }

  statement {
    sid    = "ManageWebsiteObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid    = "InvalidateCloudFront"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
    ]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "website-deploy"

  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy.json
}

#
# Preview/test deployment role
#
# This is intentionally separate from production. It can be assumed by multiple
# explicitly configured repositories/refs and can write only to configured test
# buckets / invalidate configured test distributions.
#
data "aws_iam_policy_document" "github_actions_preview_assume_role" {
  count = var.enable_preview_deploy_role ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = var.preview_github_subjects
    }
  }
}

resource "aws_iam_role" "github_preview_deploy" {
  count = var.enable_preview_deploy_role ? 1 : 0

  name = var.preview_deploy_role_name

  assume_role_policy = data.aws_iam_policy_document.github_actions_preview_assume_role[0].json

  max_session_duration = 3600

  tags = {
    Name = "GitHub Preview Deploy"
  }
}

data "aws_iam_policy_document" "github_preview_deploy" {
  count = var.enable_preview_deploy_role ? 1 : 0

  dynamic "statement" {
    for_each = length(var.preview_s3_bucket_names) > 0 ? [1] : []

    content {
      sid    = "ListPreviewBuckets"
      effect = "Allow"

      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]

      resources = [
        for bucket in var.preview_s3_bucket_names : "arn:aws:s3:::${bucket}"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.preview_s3_bucket_names) > 0 ? [1] : []

    content {
      sid    = "ManagePreviewObjects"
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]

      resources = [
        for bucket in var.preview_s3_bucket_names : "arn:aws:s3:::${bucket}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.preview_cloudfront_distribution_ids) > 0 ? [1] : []

    content {
      sid    = "InvalidatePreviewCloudFront"
      effect = "Allow"

      actions = [
        "cloudfront:CreateInvalidation"
      ]

      resources = [
        for distribution_id in var.preview_cloudfront_distribution_ids :
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${distribution_id}"
      ]
    }
  }
}

resource "aws_iam_role_policy" "github_preview_deploy" {
  count = var.enable_preview_deploy_role ? 1 : 0

  name = "preview-website-deploy"

  role   = aws_iam_role.github_preview_deploy[0].id
  policy = data.aws_iam_policy_document.github_preview_deploy[0].json
}
