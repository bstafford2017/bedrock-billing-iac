#!/bin/bash
set -e

echo "🚀 Bedrock Billing IaC - Automated AWS Setup"
echo "============================================"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="bedrock-billing-terraform-state-${ACCOUNT_ID}"
REGION="us-east-1"

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# Create S3 bucket
echo "📦 Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" 2>/dev/null || echo "Bucket already exists"

# Enable versioning
echo "🔄 Enabling S3 versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --region "$REGION"

# Enable encryption
echo "🔒 Enabling S3 encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --region "$REGION"

# Create DynamoDB table for state locking
echo "🔐 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || echo "DynamoDB table already exists"

echo ""
echo "✅ AWS infrastructure setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Add S3 permissions to GitHub Actions IAM role:"
echo "   - s3:GetObject"
echo "   - s3:PutObject"
echo "   - s3:ListBucket"
echo "2. Push code to GitHub"
echo "3. GitHub Actions will automatically create Bedrock billing resources"
echo ""
echo "🪣 S3 Bucket: $BUCKET_NAME"
echo "🔐 DynamoDB Table: terraform-locks"
