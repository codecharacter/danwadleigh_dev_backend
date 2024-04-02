output "gha_role_be_policy_arn" {
  description = "GitHub Actions role IAM policy arn"
  value       = aws_iam_policy.gha_role_be_policy.arn
}

output "tf_be_policy_arn" {
  description = "terraform_backend user IAM policy arn"
  value       = aws_iam_policy.tf_be_policy.arn
}
