###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Module: Lambda
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Creating CloudWatch metrics, SNS topics, PagerDuty
#              subscription, Chatbot and Slack integration with required 
#              IAM permissions
#  - CloudWatch: create metric alarms
#  - SNS: create Topics for CW metrics to push alarms to
#    - with subscriptions for alerting to service (PagerDuty)
#  - SSM Parameter Store: save PagerDuty integration URL and Slack IDs
#  - AWS ChatBot: configured to post alerts to Slack channel
###########################################################################

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm 
resource "aws_cloudwatch_metric_alarm" "lambda_invocation_error" {
  alarm_name                = "lambda-resume-counter-invocation-error"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 120
  statistic                 = "Sum"
  threshold                 = 2
  alarm_description         = "The metric monitors Lambda function invocation errors"
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.resume_site_alarms.arn]
  ok_actions                = [aws_sns_topic.resume_site_alarms.arn]
  insufficient_data_actions = []
}
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key 
resource "aws_kms_key" "sns_topic" {
  description         = "sns_topic"
  enable_key_rotation = true
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic 
resource "aws_sns_topic" "resume_site_alarms" {
  name              = "resume-site-alarms"
  kms_master_key_id = aws_kms_key.sns_topic.id
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "pagerduty_alerts_endpoint" {
  name = "/app/danwadleigh_dev/pagerduty_alerts_endpoint"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription 
resource "aws_sns_topic_subscription" "cloudwatch_alarms" {
  endpoint               = data.aws_ssm_parameter.pagerduty_alerts_endpoint.value
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = aws_sns_topic.resume_site_alarms.arn
}

# Create AWS Chatbot integration with Slack for CloudWatch Alarm push to SNS
# https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/iam_role
resource "awscc_iam_role" "aws_chatbot_role" {
  role_name = "aws-chatbot-role"
  assume_role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"]
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "slack_channel_id" {
  name = "/app/danwadleigh_dev/slack_channel_id"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter 
data "aws_ssm_parameter" "slack_workspace_id" {
  name = "/app/danwadleigh_dev/slack_workspace_id"
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_slack_channel_configuration 
resource "awscc_chatbot_slack_channel_configuration" "slack_channel_config" {
  configuration_name = "aws-chatbot-slack-configs"
  iam_role_arn       = awscc_iam_role.aws_chatbot_role.arn
  slack_channel_id   = data.aws_ssm_parameter.slack_channel_id.value
  slack_workspace_id = data.aws_ssm_parameter.slack_workspace_id.value

  logging_level = "INFO"
  sns_topic_arns = [
    aws_sns_topic.resume_site_alarms.arn,
  ]
}
