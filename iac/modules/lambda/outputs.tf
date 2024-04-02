output "lambda_function_arn" {
  description = "ARN of the Python counter Lambda function"
  value       = aws_lambda_function.lambda_counter.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda_counter.function_name
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of Lambda function"
  value       = aws_lambda_function.lambda_counter.invoke_arn
}

output "lambda_role" {
  description = "IAM Lambda role"
  value       = aws_iam_role.lambda_role.id
}