#!/bin/bash

# Clothe to Care - AWS S3 Deployment Script
# This script deploys the website to Amazon S3 for static website hosting

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Clothe to Care - AWS Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Configuration - UPDATE THESE VALUES
BUCKET_NAME="${1:-clothetocare-website}"  # Change this to your S3 bucket name
REGION="${2:-us-east-1}"  # Change to your preferred AWS region
PROFILE="${3:-default}"  # Change if using a specific AWS CLI profile
USE_CLOUDFORMATION="${4:-false}"  # Set to 'true' to use CloudFormation deployment

# Validate that Website directory exists
if [ ! -d "Website" ]; then
    echo -e "${RED}Error: Website directory not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed.${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo -e "${BLUE}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity --profile "$PROFILE" &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured properly.${NC}"
    echo "Run: aws configure --profile $PROFILE"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials verified${NC}\n"

# Option 1: CloudFormation Deployment (Infrastructure as Code)
if [ "$USE_CLOUDFORMATION" = "true" ]; then
    echo -e "${BLUE}Deploying with CloudFormation...${NC}"
    
    STACK_NAME="clothetocare-website"
    
    # Create or update stack
    echo -e "${BLUE}Creating/Updating CloudFormation stack: $STACK_NAME${NC}"
    aws cloudformation deploy \
        --template-file aws/cloudformation-template.yaml \
        --stack-name "$STACK_NAME" \
        --parameter-overrides BucketName="$BUCKET_NAME" \
        --region "$REGION" \
        --profile "$PROFILE" \
        --no-fail-on-empty-changeset
    
    echo -e "${GREEN}✓ CloudFormation stack deployed${NC}"
    
    # Wait for stack to be complete
    echo -e "${BLUE}Waiting for stack creation/update to complete...${NC}"
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --profile "$PROFILE" 2>/dev/null || \
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --profile "$PROFILE" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Stack ready${NC}"
    
    # Get bucket name from stack
    BUCKET_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
        --output text \
        --region "$REGION" \
        --profile "$PROFILE")
else
    # Option 2: Manual S3 Deployment (Simple, Public Access - NOT RECOMMENDED for production)
    echo -e "${YELLOW}Warning: Using public S3 bucket approach (not best practice).${NC}"
    echo -e "${YELLOW}For production, use CloudFormation with CloudFront: ./deploy-to-aws.sh clothetocare-website us-east-1 default true${NC}\n"
    
    # Create S3 bucket if it doesn't exist
    echo -e "${BLUE}Checking if S3 bucket exists...${NC}"
    if ! aws s3 ls "s3://$BUCKET_NAME" --profile "$PROFILE" 2>&1 | grep -q 'NoSuchBucket'; then
        echo -e "${GREEN}✓ Bucket '$BUCKET_NAME' exists${NC}"
    else
        echo -e "${BLUE}Creating S3 bucket '$BUCKET_NAME'...${NC}"
        if [ "$REGION" == "us-east-1" ]; then
            aws s3 mb "s3://$BUCKET_NAME" --profile "$PROFILE" || true
        else
            aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" --profile "$PROFILE" || true
        fi
        echo -e "${GREEN}✓ Bucket created${NC}"
    fi

    # Enable static website hosting
    echo -e "\n${BLUE}Configuring S3 bucket for static website hosting...${NC}"
    aws s3 website "s3://$BUCKET_NAME" \
        --index-document index.html \
        --error-document 404.html \
        --profile "$PROFILE"

    echo -e "${GREEN}✓ Static website hosting enabled${NC}"

    # Set bucket policy for public read access
    echo -e "\n${BLUE}Setting bucket policy for public access...${NC}"
    cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

    aws s3api put-bucket-policy \
        --bucket "$BUCKET_NAME" \
        --policy file:///tmp/bucket-policy.json \
        --profile "$PROFILE"

    echo -e "${GREEN}✓ Bucket policy applied${NC}"

    # Disable Block Public Access settings
    echo -e "\n${BLUE}Configuring public access settings...${NC}"
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
        --profile "$PROFILE"

    echo -e "${GREEN}✓ Public access configured${NC}"
    
    # Clean up temporary files
    rm -f /tmp/bucket-policy.json
fi

# Sync files to S3 with proper content types and cache control
echo -e "\n${BLUE}Uploading website files to S3...${NC}"

# Upload HTML files with short cache (1 hour)
aws s3 sync Website/ "s3://$BUCKET_NAME/" \
    --profile "$PROFILE" \
    --exclude "*" \
    --include "*.html" \
    --cache-control "public, max-age=3600" \
    --content-type "text/html; charset=utf-8"

# Upload CSS files with long cache (1 year)
aws s3 sync Website/css/ "s3://$BUCKET_NAME/css/" \
    --profile "$PROFILE" \
    --cache-control "public, max-age=31536000, immutable" \
    --content-type "text/css; charset=utf-8"

# Upload JavaScript files with long cache (1 year)
aws s3 sync Website/js/ "s3://$BUCKET_NAME/js/" \
    --profile "$PROFILE" \
    --cache-control "public, max-age=31536000, immutable" \
    --content-type "application/javascript; charset=utf-8"

# Upload images with long cache (1 year)
aws s3 sync Website/images/ "s3://$BUCKET_NAME/images/" \
    --profile "$PROFILE" \
    --cache-control "public, max-age=31536000, immutable"

# Upload 404.html with short cache
aws s3 cp Website/404.html "s3://$BUCKET_NAME/404.html" \
    --profile "$PROFILE" \
    --cache-control "public, max-age=3600" \
    --content-type "text/html; charset=utf-8"

echo -e "${GREEN}✓ Files uploaded successfully${NC}"

# Display results
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

if [ "$USE_CLOUDFORMATION" = "true" ]; then
    # Get CloudFront URL
    CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
        --stack-name "clothetocare-website" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
        --output text \
        --region "$REGION" \
        --profile "$PROFILE")
    
    echo -e "${GREEN}Your website is now live at:${NC}"
    echo -e "${BLUE}https://$CLOUDFRONT_URL${NC}\n"
    echo -e "${BLUE}CloudFormation Distribution ID:${NC}"
    aws cloudformation describe-stacks \
        --stack-name "clothetocare-website" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
        --output text \
        --region "$REGION" \
        --profile "$PROFILE"
else
    # Get website URL
    WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
    
    echo -e "${GREEN}Your website is now live at:${NC}"
    echo -e "${BLUE}$WEBSITE_URL${NC}\n"
fi

echo -e "${BLUE}Next steps:${NC}"
if [ "$USE_CLOUDFORMATION" != "true" ]; then
    echo -e "1. Test your website at the URL above"
    echo -e "2. RECOMMENDED: Deploy using CloudFormation for production:"
    echo -e "   ./deploy-to-aws.sh clothetocare-website $REGION $PROFILE true"
    echo -e "3. (Optional) Configure Route 53 for a custom domain"
    echo -e "4. (Optional) Set up AWS Certificate Manager for SSL/TLS"
else
    echo -e "1. Test your website at the URL above"
    echo -e "2. (Optional) Configure Route 53 for a custom domain"
    echo -e "3. To clear CloudFront cache after updates: aws cloudformation describe-stacks --stack-name clothetocare-website --query 'Stacks[0].Outputs[?OutputKey==\`CloudFrontDistributionId\`].OutputValue' --output text | xargs -I {} aws cloudfront create-invalidation --distribution-id {} --paths '/*'"
fi
echo ""
