#############################################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Author: Dan Wadleigh (dan@codecharacter.dev)
# Description: 
#  - serverless backend to integrate with frontend 
#  - using API Gateway, Lambda, and DynamoDB to retrieve, update and
#    store website visitor count
#  - monitoring and alerting solution (CloudWatch, SNS, PagerDuty, Slack)
#  - remote backend for storing state and handling locks (S3, DynamoDB)
#  - IaC (Terraform), CI/CD (GitHub Actions) and Testing (Cypress)
# Note:
#   including TF/AWS doc links for educational project assistance
# Resources:
#   Project Article: https://codecharacter.dev/semper-gumby-a-marines-journey-in-the-cloud/ 
#   Resume Site: https://DanWadleigh.dev/ 
#   LinkedIn: https://linkedin.com/in/danwadleigh
# 
#############################################################################################

module "backend" {
  source           = "./modules/remote_backend"
  bucket_name      = var.bucket_name
  iam_user_name    = var.iam_user_name
  table_name       = var.table_name
  tf_be_policy_arn = module.iam.tf_be_policy_arn
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  region            = var.region
}

module "lambda" {
  source                 = "./modules/lambda"
  http_api_execution_arn = module.api_gateway.http_api_execution_arn
  region                 = var.region
}

module "dynamodb" {
  source             = "./modules/dynamodb"
  counter_table_item = var.counter_table_item
  counter_table_name = var.counter_table_name
  lambda_role        = module.lambda.lambda_role
}

module "monitoring" {
  source = "./modules/monitoring"
}

module "iam" {
  source                        = "./modules/iam"
  bucket_name                   = var.bucket_name
  bucket_logging_be_name        = var.bucket_logging_be_name
  counter_table_name            = var.counter_table_name
  github_actions_role_be_policy = var.github_actions_role_be_policy
  github_actions_url            = var.github_actions_url
  iam_chatbot_role              = var.iam_chatbot_role
  iam_lambda_role               = var.iam_lambda_role
  iam_role_name                 = var.iam_role_name
  iam_user_name                 = var.iam_user_name
  lambda_function_name          = module.lambda.lambda_function_name
  region                        = var.region
  table_name                    = var.table_name
  terraform_backend_policy      = var.terraform_backend_policy
}
