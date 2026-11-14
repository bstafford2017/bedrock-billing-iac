# Bedrock Billing Alert - AWS Deployment Guide

## ⚠️ Current Status

The Terraform deployment failed due to insufficient IAM permissions on the OpenClaw bot user. This is expected - you'll deploy from your own AWS account with full permissions.

## 🚀 How to Deploy (3 Options)

### Option 1: Deploy Terraform from Your Local Machine (RECOMMENDED)

**Prerequisites:**
- AWS Account with admin/developer permissions
- Terraform installed locally
- AWS CLI configured with your credentials

**Steps:**

1. Clone the repository:
```bash
git clone https://github.com/bstafford2017/bedrock-billing-iac.git
cd bedrock-billing-iac
```

2. Configure your email:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your email address
nano terraform.tfvars
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

4. Confirm SNS email subscription:
   - Check your email for AWS confirmation
   - Click the link to enable alerts

**That's it!** Daily billing reports will start arriving at 8 AM UTC tomorrow.

---

### Option 2: Deploy with AWS CloudFormation (Alternative)

If you prefer CloudFormation instead of Terraform:

```bash
aws cloudformation create-stack \
  --stack-name bedrock-billing-alerts \
  --template-body file://cloudformation.yaml \
  --parameters ParameterKey=AlertEmail,ParameterValue=your-email@example.com \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

CloudFormation template coming in next commit.

---

### Option 3: Deploy Manually via AWS Console

1. **Create SNS Topic:**
   - Go to SNS > Topics > Create Topic
   - Name: `bedrock-billing-alerts`
   - Create subscription with your email

2. **Create IAM Role for Lambda:**
   - Go to IAM > Roles > Create Role
   - Service: Lambda
   - Add policies:
     - `AWSLambdaBasicExecutionRole`
     - Create custom policy with:
       ```json
       {
         "Version": "2012-10-17",
         "Statement": [
           {
             "Effect": "Allow",
             "Action": "ce:GetCostAndUsage",
             "Resource": "*"
           },
           {
             "Effect": "Allow",
             "Action": "sns:Publish",
             "Resource": "arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:bedrock-billing-alerts"
           }
         ]
       }
       ```

3. **Create Lambda Function:**
   - Go to Lambda > Create Function
   - Runtime: Python 3.11
   - Role: Use role from step 2
   - Code: Copy from `lambda_function.py`
   - Timeout: 60 seconds
   - Environment variables:
     - `SNS_TOPIC_ARN`: Your SNS topic ARN
     - `AWS_REGION`: us-east-1

4. **Create EventBridge Rule:**
   - Go to EventBridge > Rules > Create Rule
   - Schedule: `cron(0 8 * * ? *)` (8 AM UTC daily)
   - Target: Lambda function from step 3

---

## 📋 Quick Reference

| Component | Type | Purpose |
|-----------|------|---------|
| SNS Topic | AWS Service | Sends email alerts |
| Lambda Function | Compute | Fetches Bedrock costs |
| EventBridge Rule | Scheduler | Triggers Lambda daily |
| IAM Role | Access Control | Permissions for Lambda |

---

## ✅ Verification After Deployment

```bash
# Check Lambda function
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `bedrock`)]' \
  --region us-east-1

# Check SNS topic
aws sns list-topics \
  --query 'Topics[?contains(TopicArn, `bedrock`)]' \
  --region us-east-1

# View EventBridge rules
aws events list-rules \
  --query 'Rules[?contains(Name, `bedrock`)]' \
  --region us-east-1
```

---

## 🧪 Test the Deployment

**Manually trigger Lambda:**

```bash
aws lambda invoke \
  --function-name bedrock-billing-billing-checker \
  --region us-east-1 \
  /tmp/response.json

cat /tmp/response.json
```

**View Lambda logs:**

```bash
aws logs tail /aws/lambda/bedrock-billing-billing-checker \
  --region us-east-1 \
  --follow
```

---

## 🐛 Troubleshooting

### Email not arriving

- Check SNS subscription confirmation was clicked
- View SNS topic subscriptions:
  ```bash
  aws sns list-subscriptions-by-topic \
    --topic-arn arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:bedrock-billing-alerts
  ```

### Lambda execution errors

- Check CloudWatch logs:
  ```bash
  aws logs tail /aws/lambda/bedrock-billing-billing-checker --follow
  ```
- Verify Lambda has SNS publish permission
- Check SNS topic ARN in Lambda environment variable

### No Bedrock costs showing

- Bedrock must have been used in your account
- Costs take up to 24 hours to appear in billing data
- Check manually: https://console.aws.amazon.com/cost-management/

---

## 📊 Expected Daily Email

You'll receive emails like:

```
Subject: Bedrock Daily Billing Alert - 2026-11-14

Bedrock Billing Summary Report
==============================

Period: 2026-11-13 to 2026-11-14
Generated: 2026-11-14 08:00:00 UTC

Total Cost: $1.2345

Breakdown by Usage Type:
------------------------
Bedrock On-Demand: $0.9876
Bedrock Provisioned: $0.2469
```

---

## 🔧 Customization

Edit `terraform.tfvars` to customize:

```hcl
# Multiple emails (use SNS subscriptions)
alert_email = "your-email@example.com"

# Different schedule
schedule_expression = "cron(0 9 * * ? *)"  # 9 AM UTC

# Longer log retention
log_retention_days = 30
```

---

## 💾 Save State Remotely (Optional)

For production, store Terraform state in S3:

```hcl
# Uncomment in main.tf
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "bedrock-billing/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

---

## ✨ Next Steps

1. ✅ Clone repo from GitHub
2. ✅ Edit terraform.tfvars with your email
3. ✅ Run `terraform apply`
4. ✅ Confirm SNS email
5. ✅ Receive daily billing alerts

---

## 📞 Support

- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Lambda**: https://docs.aws.amazon.com/lambda/
- **SNS**: https://docs.aws.amazon.com/sns/
- **Cost Explorer**: https://docs.aws.amazon.com/awsconsolehelp/latest/gsg/billing-console.html

---

**Repository**: https://github.com/bstafford2017/bedrock-billing-iac
**Status**: Ready for deployment from your AWS account
