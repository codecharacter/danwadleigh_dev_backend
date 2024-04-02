###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Module: API
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Creating API with integration and route for FE/BE
#  - API Gateway: create API to integrate FE (JS) with BE (Lambda/DynamoDB)
#    - HTTP API, integration w/Lambda, route
#  - Lambda: API integration with Lambda function
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
## Note: API GW v2 are used for creating and deploying Websocket & HTTP APIs; to create & deploy REST APIs use v1
# AWS Docs: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html 
resource "aws_apigatewayv2_api" "lambda" {
  name          = "resume_counter_api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS", "POST", "PUT"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    max_age       = 300
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage
resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration
# AWS Docs: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html 
resource "aws_apigatewayv2_integration" "resume_counter" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = var.lambda_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route
# AWS Docs: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-routes.html 
resource "aws_apigatewayv2_route" "get_api_visits" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /api/visits"
  target    = "integrations/${aws_apigatewayv2_integration.resume_counter.id}"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "cloudwatch_kms_api_gw" {
  description         = "cloudwatch_kms_api_gw"
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
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch_kms_api_gw.arn
}

# Note: aws_apigatewayv2_domain_name & aws_apigatewayv2_api_mapping
# Located: CRC Frontend App in route53_acm module
# Link: https://github.com/codecharacter/danwadleigh_dev_frontend/blob/main/iac/modules/route53_acm/main.tf#L50-L81
# Decision: - as it's a "domain" config using ACM, opted to keep in "domain" module
#           - either app/module would have required porting some data