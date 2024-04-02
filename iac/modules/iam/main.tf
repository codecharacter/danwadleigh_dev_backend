###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Module: IAM
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Create IAM policy for Terraform Backend user
#  - IAM Access Advisor: identified allowed management actions for services
#  - IAM Policy: built based on actions accessed by user
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "tf_be_policy" {
  name        = "terraform_backend_policy"
  path        = "/"
  description = "IAM Policy actions for terraform_backend user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:CreateBucket",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetObject",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutBucketWebsite",
          "s3:PutObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_logging_be_name}",
          "arn:aws:s3:::${var.bucket_logging_be_name}/*"
        ],
      },
      {
        "Effect" : "Allow",
        "Action" : "sts:GetCallerIdentity",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:GetUser",
          "iam:ListRolePolicies",
          "iam:CreateOpenIDConnectProvider",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy"
        ],
        "Resource" : [
          "arn:aws:iam::${local.account_id}:user/${var.iam_user_name}",
          "arn:aws:iam::${local.account_id}:oidc-provider/${var.github_actions_url}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_role_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:CreateTable"
        ],
        "Resource" : "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.table_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetPolicy",
          "lambda:ListVersionsByFunction",
          "lambda:RemovePermission"
        ],
        "Resource" : "arn:aws:lambda:${var.region}:${local.account_id}:function:${var.lambda_function_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : "apigateway:*",
        "Resource" : "*"
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "gha_role_be_policy" {
  name        = "github-actions-role-be-policy"
  path        = "/"
  description = "IAM Policy actions for GitHub Actions role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:*:${local.account_id}:alarm:*",
          "arn:aws:cloudwatch:*:${local.account_id}:insight-rule/*",
          "arn:aws:cloudwatch:*:${local.account_id}:slo/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudformation:GetResource"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:PutResourcePolicy",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:CreateLogGroup",
          "logs:DescribeResourcePolicies",
          "logs:ListTagsLogGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:GetItem",
          "dynamodb:ListTagsOfResource",
          "dynamodb:PutItem"
        ],
        "Resource" : [
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.table_name}",
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/${var.counter_table_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetObject",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_logging_be_name}",
          "arn:aws:s3:::${var.bucket_logging_be_name}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "sns:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "chatbot:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:AttachRolePolicy",
          "iam:AttachUserPolicy",
          "iam:CreatePolicy",
          "iam:CreateRole",
          "iam:CreateServiceLinkedRole",
          "iam:DetachUserPolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetUser",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListRolePolicies"
        ],
        "Resource" : [
          "arn:aws:iam::${local.account_id}:user/${var.iam_user_name}",
          "arn:aws:iam::${local.account_id}:oidc-provider/${var.github_actions_url}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_role_name}",
          "arn:aws:iam::${local.account_id}:policy/${var.github_actions_role_be_policy}",
          "arn:aws:iam::${local.account_id}:policy/${var.terraform_backend_policy}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_lambda_role}",
          "arn:aws:iam::${local.account_id}:role/${var.iam_chatbot_role}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:decrypt",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:GenerateDataKey"
        ],
        "Resource" : [
          "arn:aws:kms:${var.region}:${local.account_id}:key/ebb453b5-a5fe-4ac2-945c-cad890471fea",
          "arn:aws:kms:${var.region}:${local.account_id}:key/56b502e5-954d-436c-a3b5-12dbb3a22ae6",
          "arn:aws:kms:${var.region}:${local.account_id}:key/4fc5438c-cc2d-421f-944b-3796f814fbc3",
          "arn:aws:kms:${var.region}:${local.account_id}:key/1ce53e84-3cdc-4d48-b2a8-a285ccd0243a",
          "arn:aws:kms:${var.region}:${local.account_id}:key/b932b2e8-adce-412c-bf42-181dc38a8487",
          "arn:aws:kms:${var.region}:${local.account_id}:key/0e026165-87a7-4dc9-8af2-2cd5d9fe93ec"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetPolicy",
          "lambda:ListVersionsByFunction",
          "lambda:RemovePermission",
          "lambda:UpdateFunctionCode"
        ],
        "Resource" : "arn:aws:lambda:${var.region}:${local.account_id}:function:${var.lambda_function_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : "sts:GetCallerIdentity",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ssm:GetParameter",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "apigateway:*",
        "Resource" : "*"
      }
    ]
  })
}