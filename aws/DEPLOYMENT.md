# AWS Deployment Guide for Clothe to Care Website

This guide explains how to deploy the Clothe to Care website to Amazon Web Services (AWS).

## Prerequisites

1. **AWS Account**: Create an account at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI**: Install the AWS CLI tool
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Windows
   # Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
   ```

3. **Configure AWS CLI**: Set up your credentials
   ```bash
   aws configure
   ```
   Enter your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., `us-east-1`)
   - Default output format (e.g., `json`)

## Deployment Options

### Option 1: Quick Deployment with Script (Recommended)

1. **Edit the deployment script** to configure your settings:
   ```bash
   nano deploy-to-aws.sh
   ```
   Update these variables:
   - `BUCKET_NAME`: Your desired S3 bucket name (must be globally unique)
   - `REGION`: Your preferred AWS region (e.g., `us-east-1`)
   - `PROFILE`: Your AWS CLI profile name (default: `default`)

2. **Run the deployment script**:
   ```bash
   ./deploy-to-aws.sh
   ```

3. **Access your website** at the URL provided by the script:
   ```
   http://your-bucket-name.s3-website-region.amazonaws.com
   ```

### Option 2: CloudFormation Deployment (Infrastructure as Code)

For a more robust setup with CloudFront CDN:

1. **Deploy using CloudFormation**:
   ```bash
   aws cloudformation create-stack \
     --stack-name clothetocare-website \
     --template-body file://aws/cloudformation-template.yaml \
     --parameters ParameterKey=BucketName,ParameterValue=your-unique-bucket-name \
     --region us-east-1
   ```

2. **Wait for stack creation** (takes 5-10 minutes):
   ```bash
   aws cloudformation wait stack-create-complete \
     --stack-name clothetocare-website \
     --region us-east-1
   ```

3. **Upload website files**:
   ```bash
   BUCKET_NAME=$(aws cloudformation describe-stacks \
     --stack-name clothetocare-website \
     --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
     --output text)
   
   aws s3 sync Website/ s3://$BUCKET_NAME --delete
   ```

4. **Get your website URLs**:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name clothetocare-website \
     --query 'Stacks[0].Outputs'
   ```

### Option 3: Manual AWS Console Deployment

1. **Create S3 Bucket**:
   - Go to [S3 Console](https://console.aws.amazon.com/s3/)
   - Click "Create bucket"
   - Enter a unique bucket name
   - Choose your region
   - Uncheck "Block all public access"
   - Create the bucket

2. **Enable Static Website Hosting**:
   - Click on your bucket
   - Go to "Properties" tab
   - Scroll to "Static website hosting"
   - Enable it
   - Set index document: `index.html`
   - Set error document: `404.html`

3. **Set Bucket Policy**:
   - Go to "Permissions" tab
   - Click "Bucket Policy"
   - Paste the policy from `aws/s3-bucket-policy.json`
   - Replace `BUCKET_NAME_HERE` with your bucket name
   - Save changes

4. **Upload Files**:
   - Go to "Objects" tab
   - Click "Upload"
   - Drag and drop all website files
   - Click "Upload"

5. **Access Website**:
   - Go back to "Properties" → "Static website hosting"
   - Copy the "Bucket website endpoint" URL

## Adding Custom Domain

### Using Route 53

1. **Register or transfer domain** to Route 53

2. **Request SSL Certificate** (AWS Certificate Manager):
   ```bash
   aws acm request-certificate \
     --domain-name clothetocare.org \
     --domain-name www.clothetocare.org \
     --validation-method DNS \
     --region us-east-1
   ```

3. **Create CloudFront distribution** (if not using CloudFormation):
   - Point it to your S3 bucket
   - Add SSL certificate
   - Add custom domain names

4. **Update Route 53**:
   - Create A record (alias) pointing to CloudFront distribution

## Updating the Website

### Quick Update
```bash
aws s3 sync Website/ s3://your-bucket-name --delete
```

### Update with Cache Invalidation (if using CloudFront)
```bash
# Sync files
aws s3 sync Website/ s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## Cost Estimation

**S3 Hosting Only** (estimated monthly costs):
- Storage (1 GB): ~$0.02
- Requests (10,000): ~$0.01
- Data transfer (10 GB): ~$0.90
- **Total**: ~$1/month

**With CloudFront**:
- Add ~$1-5/month depending on traffic
- Includes HTTPS and global CDN

**Free Tier Benefits** (first 12 months):
- 5 GB S3 storage
- 20,000 GET requests
- 2,000 PUT requests
- 50 GB CloudFront data transfer

## Security Best Practices

1. **Enable CloudFront** for HTTPS
2. **Use SSL/TLS certificates** from AWS Certificate Manager (free)
3. **Enable versioning** on S3 bucket for backup
4. **Set up CloudWatch alarms** for unusual activity
5. **Use IAM roles** with minimal permissions
6. **Enable S3 access logging**

## Monitoring

### Enable S3 Access Logging
```bash
aws s3api put-bucket-logging \
  --bucket your-bucket-name \
  --bucket-logging-status file://logging-config.json
```

### CloudWatch Metrics
- Monitor in AWS Console → CloudWatch
- Track: Requests, Bandwidth, Errors

## Troubleshooting

### Website shows XML instead of HTML
- Check that Static Website Hosting is enabled
- Use the website endpoint, not the S3 endpoint

### 403 Forbidden Error
- Check bucket policy is correct
- Verify public access settings
- Ensure files have correct permissions

### Changes not appearing
- Clear browser cache
- Invalidate CloudFront cache (if using CloudFront)
- Check file was uploaded correctly

## Backup and Disaster Recovery

### Create Backup
```bash
aws s3 sync s3://your-bucket-name ./backup-$(date +%Y%m%d)
```

### Enable Versioning
```bash
aws s3api put-bucket-versioning \
  --bucket your-bucket-name \
  --versioning-configuration Status=Enabled
```

## Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront with S3](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GettingStarted.SimpleDistribution.html)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/)

## Support

For issues with:
- **Website content**: Contact Clothe to Care
- **AWS deployment**: Check AWS documentation or AWS Support
- **This guide**: Open an issue in the project repository
