#!/bin/bash

# Clothe to Care - AWS S3 Deployment Script
# This script deploys the website to Amazon S3 for static website hosting

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Clothe to Care - AWS Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Configuration - UPDATE THESE VALUES
BUCKET_NAME="clothetocare-website"  # Change this to your S3 bucket name
REGION="us-east-1"  # Change to your preferred AWS region
PROFILE="default"  # Change if using a specific AWS CLI profile

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed.${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo -e "${BLUE}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity --profile $PROFILE &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured properly.${NC}"
    echo "Run: aws configure --profile $PROFILE"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials verified${NC}\n"

# Create S3 bucket if it doesn't exist
echo -e "${BLUE}Checking if S3 bucket exists...${NC}"
if ! aws s3 ls "s3://$BUCKET_NAME" --profile $PROFILE 2>&1 | grep -q 'NoSuchBucket'; then
    echo -e "${GREEN}✓ Bucket '$BUCKET_NAME' exists${NC}"
else
    echo -e "${BLUE}Creating S3 bucket '$BUCKET_NAME'...${NC}"
    if [ "$REGION" == "us-east-1" ]; then
        aws s3 mb "s3://$BUCKET_NAME" --profile $PROFILE
    else
        aws s3 mb "s3://$BUCKET_NAME" --region $REGION --profile $PROFILE
    fi
    echo -e "${GREEN}✓ Bucket created${NC}"
fi

# Enable static website hosting
echo -e "\n${BLUE}Configuring S3 bucket for static website hosting...${NC}"
aws s3 website "s3://$BUCKET_NAME" \
    --index-document index.html \
    --error-document 404.html \
    --profile $PROFILE

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
    --bucket $BUCKET_NAME \
    --policy file:///tmp/bucket-policy.json \
    --profile $PROFILE

echo -e "${GREEN}✓ Bucket policy applied${NC}"

# Disable Block Public Access settings
echo -e "\n${BLUE}Configuring public access settings...${NC}"
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    --profile $PROFILE

echo -e "${GREEN}✓ Public access configured${NC}"

# Sync files to S3
echo -e "\n${BLUE}Uploading website files to S3...${NC}"
aws s3 sync Website/ "s3://$BUCKET_NAME" \
    --profile $PROFILE \
    --exclude ".DS_Store" \
    --delete \
    --cache-control "public, max-age=3600"

# Set specific cache control for static assets
echo -e "\n${BLUE}Optimizing cache settings...${NC}"
aws s3 cp s3://$BUCKET_NAME/css/ s3://$BUCKET_NAME/css/ \
    --recursive \
    --metadata-directive REPLACE \
    --cache-control "public, max-age=31536000" \
    --profile $PROFILE

aws s3 cp s3://$BUCKET_NAME/js/ s3://$BUCKET_NAME/js/ \
    --recursive \
    --metadata-directive REPLACE \
    --cache-control "public, max-age=31536000" \
    --profile $PROFILE

echo -e "${GREEN}✓ Files uploaded successfully${NC}"

# Get website URL
WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${GREEN}Your website is now live at:${NC}"
echo -e "${BLUE}$WEBSITE_URL${NC}\n"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Test your website at the URL above"
echo -e "2. (Optional) Set up CloudFront for HTTPS and better performance"
echo -e "3. (Optional) Configure Route 53 for custom domain"
echo -e "4. (Optional) Set up AWS Certificate Manager for SSL/TLS\n"

# Clean up temporary files
rm -f /tmp/bucket-policy.json
