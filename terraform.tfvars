aws_region   = "us-east-1"
environment  = "production"
project_name = "bedrock-billing"
alert_email  = "bstafford2017@gmail.com"  # CHANGE THIS
schedule_expression = "cron(0 8 * * ? *)"  # 8 AM UTC daily
log_retention_days  = 7
lookback_days       = 1

tags = {
  Team       = "Platform"
  CostCenter = "Engineering"
}
