output "gha_role_be_policy_arn" {
  description = "GitHub Actions role IAM policy arn"
  value       = module.iam.gha_role_be_policy_arn
}

output "http_api_execution_arn" {
  description = "API Execution ARN"
  value       = module.api_gateway.http_api_execution_arn
}

output "iam_user_name" {
  description = "IAM User for Backend Terraform"
  value       = module.backend.iam_user_arn
}

output "lambda_function_arn" {
  description = "ARN of the Python counter Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "tf_be_policy_arn" {
  description = "terraform_backend user IAM policy arn"
  value       = module.iam.tf_be_policy_arn
}
