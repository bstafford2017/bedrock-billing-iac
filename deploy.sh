#!/bin/bash
set -e

echo "🚀 Bedrock Billing Alert - Deployment Script"
echo "=============================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform >= 1.0"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.11+"
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# Check configuration
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found"
    echo "📋 Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  PLEASE EDIT terraform.tfvars and set alert_email before continuing!"
    exit 1
fi

# Verify email is set
if grep -q "your-email@example.com" terraform.tfvars; then
    echo "❌ Email not configured in terraform.tfvars"
    echo "⚠️  Please update alert_email before deploying"
    exit 1
fi

echo "📧 Email configured: $(grep alert_email terraform.tfvars)"
echo ""

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

echo ""
echo "📊 Planning deployment..."
terraform plan -out=tfplan

echo ""
echo "⏳ Ready to deploy. Review the plan above."
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Deploying infrastructure..."
terraform apply tfplan

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Deployment Summary:"
terraform output

echo ""
echo "⚠️  IMPORTANT: Check your email for SNS subscription confirmation"
echo "📧 Click the confirmation link to enable billing alerts"
echo ""
echo "🔗 View deployment:"
echo "   - SNS Topic: $(terraform output -raw sns_topic_arn)"
echo "   - Lambda Function: $(terraform output -raw lambda_function_name)"
echo "   - EventBridge Rule: $(terraform output -raw eventbridge_rule_name)"
echo ""
echo "📖 For troubleshooting, see README.md"
