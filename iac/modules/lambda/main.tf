###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Module: Lambda
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Creating Lambda function with required IAM permissions
#  - Lambda: create function to retrieve & update counter in DB
#  - Python: function written with boto3 Library
#  - IAM Role: allow Lambda execution invoked from API Gateway
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file 
data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "${path.root}/../lambda/lambda_function.py"
  output_path = "${path.root}/../lambda/lambda_function.zip"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function 
#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "lambda_counter" {
  filename         = "${path.root}/../lambda/lambda_function.zip"
  function_name    = "resume_counter_lambda"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  timeout          = 10
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role 
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole",
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment 
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission 
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_counter.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.http_api_execution_arn}/*/*"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "cloudwatch_kms_lambda" {
  description         = "cloudwatch_kms_lambda"
  enable_key_rotation = true

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "default",
    "Statement" : [
      {
        "Sid" : "DefaultAllow",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${local.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"

      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group 
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_counter.function_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_kms_lambda.arn
}