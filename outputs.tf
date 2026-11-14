output "sns_topic_arn" {
  description = "SNS topic ARN for billing alerts"
  value       = aws_sns_topic.bedrock_billing_alerts.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.bedrock_billing_lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.bedrock_billing_lambda.arn
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name"
  value       = aws_cloudwatch_event_rule.bedrock_billing_daily.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.bedrock_billing_logs.name
}

output "deployment_info" {
  description = "Deployment information summary"
  value = {
    region              = data.aws_region.current.name
    account_id          = data.aws_caller_identity.current.account_id
    sns_topic           = aws_sns_topic.bedrock_billing_alerts.name
    lambda_function     = aws_lambda_function.bedrock_billing_lambda.function_name
    alert_email         = var.alert_email
    schedule            = var.schedule_expression
    log_group           = aws_cloudwatch_log_group.bedrock_billing_logs.name
  }
}
