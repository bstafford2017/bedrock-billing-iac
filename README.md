# Bedrock Daily Billing Alert - Infrastructure as Code

Complete Terraform setup for daily AWS Bedrock billing alerts via email.

## Architecture

```
EventBridge Rule (Daily 8 AM UTC)
         ↓
    Lambda Function
         ↓
Cost Explorer API (fetch Bedrock costs)
         ↓
    SNS Topic
         ↓
    Email Alert
```

## Features

✅ Daily automated billing reports
✅ Sends email with cost breakdown
✅ Tracks usage by service type
✅ Error notifications
✅ Automatic log retention
✅ Production-ready with IAM policies
✅ Easy deployment with Terraform
✅ Customizable schedule and email

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- Python 3.11+ (for Lambda deployment package)

## Quick Start

### 1. Copy and Edit Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your email address
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Deployment Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

### 5. Confirm Email Subscription

AWS will send a confirmation email. Click the confirmation link to enable alerts.

### 6. Verify Deployment

```bash
# Check Lambda function
aws lambda list-functions --query 'Functions[?contains(FunctionName, `bedrock`)]'

# View EventBridge rule
aws events list-rules --query 'Rules[?contains(Name, `bedrock`)]'

# Check SNS topic
aws sns list-topics --query 'Topics[?contains(TopicArn, `bedrock`)]'
```

## Configuration

Edit `terraform.tfvars`:

```hcl
# Email to receive billing alerts
alert_email = "your-email@example.com"

# Schedule: cron(0 8 * * ? *) = 8 AM UTC daily
schedule_expression = "cron(0 8 * * ? *)"

# How many days to retain logs
log_retention_days = 7

# How many days back to check billing
lookback_days = 1
```

## Schedule Expressions

| Time | Expression |
|------|-----------|
| 8 AM UTC Daily | `cron(0 8 * * ? *)` |
| 9 AM UTC Daily | `cron(0 9 * * ? *)` |
| Noon UTC Daily | `cron(0 12 * * ? *)` |
| 9 PM UTC Daily | `cron(0 21 * * ? *)` |
| Midnight UTC Daily | `cron(0 0 * * ? *)` |
| Weekdays 8 AM UTC | `cron(0 8 ? * MON-FRI *)` |

## Files

- `main.tf` - Primary infrastructure (SNS, Lambda, EventBridge, IAM)
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `archive.tf` - Lambda function archiving
- `lambda_function.py` - Python code for billing check
- `terraform.tfvars.example` - Example configuration

## Testing

### Test Lambda Manually

```bash
# Get Lambda function name
LAMBDA_NAME=$(terraform output -raw lambda_function_name)

# Invoke function
aws lambda invoke \
  --function-name $LAMBDA_NAME \
  --region us-east-1 \
  /tmp/lambda_response.json

# View response
cat /tmp/lambda_response.json | jq .
```

### View Lambda Logs

```bash
# Get log group name
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)

# View recent logs
aws logs tail $LOG_GROUP --follow --since 1h
```

### Monitor SNS Topic

```bash
# Get SNS topic ARN
SNS_ARN=$(terraform output -raw sns_topic_arn)

# List subscriptions
aws sns list-subscriptions-by-topic --topic-arn $SNS_ARN
```

## Troubleshooting

### Email Not Arriving

1. Check SNS subscription confirmation was clicked
2. Check spam/junk folder
3. Verify email in `terraform.tfvars`
4. View Lambda logs: `aws logs tail LOG_GROUP --follow`

### Lambda Execution Errors

```bash
# View Lambda errors
aws logs tail /aws/lambda/bedrock-billing-billing-checker --follow

# Check Lambda permissions
aws lambda get-policy --function-name bedrock-billing-billing-checker
```

### Bedrock Costs Not Showing

1. Ensure Bedrock has been used in your account
2. Costs may take 24 hours to appear in billing data
3. Check Cost Explorer manually: https://console.aws.amazon.com/cost-management/home?region=us-east-1#/custom

## Cost Estimation

Monthly costs (approximate):
- Lambda: Free tier (1M requests/month included)
- CloudWatch Logs: ~$0.50 (7-day retention)
- SNS: ~$0.50 (1 email/day = 30 emails/month)
- **Total: ~$1.00/month** (or free if within free tier)

## Cleanup

Remove all resources:

```bash
terraform destroy
```

Confirm SNS subscription was removed:

```bash
aws sns list-subscriptions --query 'Subscriptions[?contains(TopicArn, `bedrock`)]'
```

## Next Steps

1. Deploy infrastructure
2. Confirm SNS email subscription
3. Verify first billing alert arrives tomorrow at 8 AM UTC
4. Customize schedule or email as needed

## Support

For issues:
1. Check Lambda logs in CloudWatch
2. Verify IAM permissions
3. Test Lambda manually
4. Check SNS subscription status

---

**Repository**: Deploy from `/tmp/bedrock-billing-iac/`
**Status**: Production-ready
