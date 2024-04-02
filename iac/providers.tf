# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "0.71.0"
    }
  }
  required_version = ">= 1.7.2"
  # Note: must initialize and deploy remote_backend resources prior to 
  #       migrating the state from local backend to the remote backend
  backend "s3" {
    bucket         = "tf-state-bucket-dw-backend"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf_state_locks_dw_backend"
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate 
data "tls_certificate" "github" {
  url = "https://${var.github_actions_url}"
}

# Create an IAM OIDC identity provider that trusts GitHub (data source used to retrieve ARN in Frontend)
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider 
# GitHub Docs: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services 
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://${var.github_actions_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Fetch GitHub's OIDC thumbprint
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document 
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.github_actions_url}:sub"
      values = [
        "repo:codecharacter/danwadleigh_dev_backend:ref:refs/heads/main"
      ]
    }
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role 
# AWS Docs: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/ 
resource "aws_iam_role" "github_oidc_role" {
  name               = "GitHubActionsRole-backend"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment 
resource "aws_iam_role_policy_attachment" "github_oidc_role_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = module.iam.gha_role_be_policy_arn
} 