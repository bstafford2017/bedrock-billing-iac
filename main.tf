terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bedrock-billing-terraform-state-749936333804"
    key            = "bedrock-billing/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Bedrock Billing Alert"
      ManagedBy   = "Terraform"
    }
  }
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

# SNS Topic for billing alerts
resource "aws_sns_topic" "bedrock_billing_alerts" {
  name = "${var.project_name}-billing-alerts"

  tags = {
    Name = "Bedrock Billing Alerts Topic"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# SNS Topic subscription - Email
resource "aws_sns_topic_subscription" "bedrock_billing_email" {
  topic_arn = aws_sns_topic.bedrock_billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.bedrock_billing_alerts]
}

# IAM Role for Lambda
resource "aws_iam_role" "bedrock_billing_lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda - CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.bedrock_billing_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda - Cost Explorer and SNS
resource "aws_iam_role_policy" "bedrock_billing_policy" {
  name   = "${var.project_name}-policy"
  role   = aws_iam_role.bedrock_billing_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.bedrock_billing_alerts.arn
      }
    ]
  })
}

# Lambda function for billing report
resource "aws_lambda_function" "bedrock_billing_lambda" {
  filename      = "lambda_function.zip"
  function_name = "${var.project_name}-billing-checker"
  role          = aws_iam_role.bedrock_billing_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.bedrock_billing_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.bedrock_billing_policy
  ]
}

# EventBridge Rule for daily trigger (8 AM UTC)
resource "aws_cloudwatch_event_rule" "bedrock_billing_daily" {
  name                = "${var.project_name}-daily-trigger"
  description         = "Trigger Bedrock billing report daily at 8 AM UTC"
  schedule_expression = var.schedule_expression

  tags = {
    Name = "Bedrock Billing Daily Trigger"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "bedrock_billing_lambda" {
  rule      = aws_cloudwatch_event_rule.bedrock_billing_daily.name
  target_id = "BedrockBillingLambda"
  arn       = aws_lambda_function.bedrock_billing_lambda.arn

  depends_on = [
    aws_lambda_permission.allow_eventbridge
  ]
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_billing_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bedrock_billing_daily.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "bedrock_billing_logs" {
  name              = "/aws/lambda/${aws_lambda_function.bedrock_billing_lambda.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "Bedrock Billing Lambda Logs"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current region
data "aws_region" "current" {}
