###########################################################################
# Project: AWS Cloud Resume Challenge with DevOps mods
# App: CRC Backend
# Module: Database
# Author: Dan Wadleigh (dan@codecharacter.dev)
#
# Note:
#   including TF/AWS doc links for educational CRC project assistance only
#
# Description: Creating DB table and item with required IAM policy
#  - DynamoDB: create Table and Item for visitor counter
#  - IAM Policy: allow Lambda to retrieve and update DB counter
###########################################################################

# DynamoDB Table for Resume Site Counter Views
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table 
resource "aws_dynamodb_table" "counter_views_table" {
  name         = var.counter_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  table_class  = "STANDARD"

  # Define primary key attributes
  attribute {
    name = "id"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = true

  #tfsec:ignore:aws-dynamodb-table-customer-key
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = var.counter_table_name
  }
}

# Table Item
# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item 
resource "aws_dynamodb_table_item" "counter_item" {
  table_name = aws_dynamodb_table.counter_views_table.name
  hash_key   = aws_dynamodb_table.counter_views_table.hash_key

  item = <<ITEM
  {
    "id": { "S": "${var.counter_table_item}" },
    "visitor_count": { "N": "0" }
  }
  ITEM

  lifecycle {
    ignore_changes = all
  }
}

# TF Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy 
resource "aws_iam_role_policy" "dynamodb-lambda-policy" {
  name = "dynamodb-lambda-policy"
  role = var.lambda_role
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:*"],
        Resource = "${aws_dynamodb_table.counter_views_table.arn}"
      }
    ]
  })
}