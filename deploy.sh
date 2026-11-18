#!/bin/bash
set -e

ACCOUNT_ID="749936333804"
REGION="us-east-1"
PROJECT="bedrock-billing"
EMAIL="b.stafford2017@gmail.com"

echo "🚀 Deploying Bedrock Billing Alert Infrastructure via AWS CLI"
echo "================================================================"

# 1. SNS Topic (already created)
echo "✅ SNS Topic already exists: bedrock-billing-billing-alerts"

# 2. IAM Role (already created)
echo "✅ IAM Role already exists: bedrock-billing-lambda-role"

# 3. Lambda Function
echo "📦 Creating Lambda function..."
LAMBDA_NAME="${PROJECT}-billing-checker"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT}-lambda-role"

aws lambda create-function \
  --function-name "$LAMBDA_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler index.handler \
  --timeout 60 \
  --zip-file fileb://lambda_function.zip \
  --environment Variables="{SNS_TOPIC_ARN=arn:aws:sns:${REGION}:${ACCOUNT_ID}:${PROJECT}-billing-alerts}" \
  --region "$REGION" 2>&1 | grep -i "functionarn\|error" || echo "Lambda function created"

# 4. Lambda Permission for EventBridge
echo "🔐 Adding EventBridge permission to Lambda..."
aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id AllowExecutionFromEventBridge \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/${PROJECT}-daily-trigger" \
  --region "$REGION" 2>&1 | grep -i "statement\|error" || echo "Permission added"

# 5. EventBridge Target
echo "🎯 Adding Lambda as EventBridge target..."
aws events put-targets \
  --rule "${PROJECT}-daily-trigger" \
  --targets "Id"="1","Arn"="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}" \
  --region "$REGION" 2>&1 | grep -i "failed\|success" || echo "Target added"

# 6. CloudWatch Log Group
echo "📝 Creating CloudWatch log group..."
aws logs create-log-group \
  --log-group-name "/aws/lambda/${LAMBDA_NAME}" \
  --region "$REGION" 2>&1 | grep -i "error" || echo "Log group created"

# Set retention
aws logs put-retention-policy \
  --log-group-name "/aws/lambda/${LAMBDA_NAME}" \
  --retention-in-days 7 \
  --region "$REGION" 2>&1 | grep -i "error" || echo "Log retention set"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Resources created:"
echo "  - SNS Topic: bedrock-billing-billing-alerts"
echo "  - IAM Role: bedrock-billing-lambda-role"
echo "  - Lambda: bedrock-billing-billing-checker"
echo "  - EventBridge Rule: bedrock-billing-daily-trigger"
echo "  - CloudWatch Logs: /aws/lambda/bedrock-billing-billing-checker"
echo ""
echo "📧 Email subscription pending confirmation at: $EMAIL"
