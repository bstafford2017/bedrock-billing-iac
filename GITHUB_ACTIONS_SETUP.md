# GitHub Actions Terraform Deployment - IAM Setup Guide

## AWS IAM Role Setup

### Step 1: Create IAM Role for GitHub Actions

1. Go to AWS IAM Console → Roles → Create Role
2. Trust entity type: Web identity
3. Identity provider: Token.actions.githubusercontent.com
4. Audience: sts.amazonaws.com
5. Subject: `repo:bstafford2017/bedrock-billing-iac:*`

### Step 2: Attach Permissions Policy

Copy the policy from `IAM_POLICY.json` and attach to the role.

**Key permissions needed:**
- SNS: Create/manage topics and subscriptions
- Lambda: Create/update/delete functions
- IAM: Create/manage roles and policies
- EventBridge: Create/manage rules and targets
- CloudWatch Logs: Create/manage log groups
- S3 & DynamoDB: For Terraform state (optional)

### Step 3: Add GitHub Secrets

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add new secret: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::ACCOUNT_ID:role/github-terraform-role`

### Step 4: Configure Workflow

Update `.github/workflows/deploy.yml`:
- Set `AWS_REGION` (default: us-east-1)
- Update `role-to-assume` to use secret

## Minimal IAM Policy

For **read-only preview** (pull requests):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:ListTopics",
        "lambda:ListFunctions",
        "events:ListRules",
        "logs:DescribeLogGroups",
        "iam:GetRole"
      ],
      "Resource": "*"
    }
  ]
}
```

For **full deployment** (main branch):
Use complete policy from `IAM_POLICY.json`

## Workflow Behavior

| Trigger | Action |
|---------|--------|
| Pull Request | Plan only (shows what would change) |
| Push to main | Plan + Apply (auto-deploys) |
| Manual trigger | Plan only |

## Testing

1. Create test branch
2. Push to GitHub
3. GitHub Actions runs `terraform plan`
4. Review plan in PR
5. Merge to main → auto-deploys

## Files

- `.github/workflows/deploy.yml` - GitHub Actions workflow
- `IAM_POLICY.json` - Required permissions

---

**Status:** Ready for GitHub Actions deployment
