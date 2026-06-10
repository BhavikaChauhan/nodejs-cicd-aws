#!/bin/bash
# ================================================================
# Creates the ECR repository and IAM user for CI/CD
# Run this ONCE from your local machine before first deploy
# Requirements: AWS CLI configured locally (aws configure)
# ================================================================

set -e

REGION="ap-south-1"
REPO_NAME="nodejs-cicd-app"
IAM_USER="github-actions-cicd"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🚀 Setting up AWS resources for CI/CD..."
echo "Account: ${ACCOUNT_ID} | Region: ${REGION}"

# ── Create ECR Repository ──────────────────────────────────────
echo "📦 Creating ECR repository: ${REPO_NAME}"
aws ecr create-repository \
  --repository-name ${REPO_NAME} \
  --region ${REGION} \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  2>/dev/null || echo "Repository already exists"

ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"
echo "✅ ECR URI: ${ECR_URI}"

# ── Create IAM user for GitHub Actions ────────────────────────
echo "👤 Creating IAM user: ${IAM_USER}"
aws iam create-user --user-name ${IAM_USER} 2>/dev/null || echo "User already exists"

# Minimal permissions policy — only what CI/CD needs
cat > /tmp/cicd-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:${REGION}:${ACCOUNT_ID}:repository/${REPO_NAME}"
    }
  ]
}
EOF

aws iam put-user-policy \
  --user-name ${IAM_USER} \
  --policy-name "cicd-ecr-policy" \
  --policy-document file:///tmp/cicd-policy.json

# Create access keys
echo "🔑 Creating access keys..."
KEYS=$(aws iam create-access-key --user-name ${IAM_USER})
ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $KEYS | jq -r '.AccessKey.SecretAccessKey')

echo ""
echo "✅ ═══════════════════════════════════════════════════"
echo "   Add these to GitHub Secrets (Settings → Secrets):"
echo ""
echo "   AWS_ACCESS_KEY_ID     = ${ACCESS_KEY}"
echo "   AWS_SECRET_ACCESS_KEY = ${SECRET_KEY}"
echo "   ECR_REPOSITORY        = ${REPO_NAME}"
echo ""
echo "   Also add:"
echo "   STAGING_EC2_IP        = <your staging EC2 public IP>"
echo "   PROD_EC2_IP           = <your prod EC2 public IP>"
echo "   EC2_SSH_KEY           = <contents of your .pem file>"
echo "   SLACK_WEBHOOK_URL     = <your Slack webhook URL>"
echo "═══════════════════════════════════════════════════"
