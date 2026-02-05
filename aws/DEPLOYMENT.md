# AWS Deployment Guide for Clothe to Care Website

This guide explains how to deploy the Clothe to Care website to Amazon Web Services (AWS).

## Quick Start

The fastest way to deploy with production-ready settings:

```bash
# 1. Make sure you're in the project root directory
cd /path/to/CTC_WS_01

# 2. Deploy with CloudFormation (Production Recommended)
./deploy-to-aws.sh clothetocare-website us-east-1 default true

# Your website will be live with HTTPS, CDN, and security best practices!
```

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

### Option 1: Quick Deployment with CloudFormation (RECOMMENDED)

**Best for:** Production deployments with maximum performance and security.

Includes: CloudFront CDN, HTTPS, Origin Access Identity, automatic caching, security headers.

1. **Run the deployment script**:
   ```bash
   ./deploy-to-aws.sh clothetocare-website us-east-1 default true
   ```

2. **Script arguments** (all optional):
   - `clothetocare-website` - S3 bucket name (must be globally unique)
   - `us-east-1` - AWS region
   - `default` - AWS CLI profile name
   - `true` - Use CloudFormation deployment

3. **Access your website** at the URL provided by the script (HTTPS CloudFront URL)

### Option 2: Simple S3 Deployment

**Best for:** Development or testing environments.

Uses public S3 bucket hosting (not recommended for production).

```bash
./deploy-to-aws.sh
```

This will:
- Create an S3 bucket
- Enable static website hosting
- Upload your website files
- Output the S3 website URL (HTTP only)

### Option 3: Manual CloudFormation Deployment

For more control, deploy CloudFormation directly:

1. **Deploy using CloudFormation**:
   ```bash
   aws cloudformation create-stack \
     --stack-name clothetocare-website \
     --template-body file://aws/cloudformation-template.yaml \
     --parameters ParameterKey=BucketName,ParameterValue=clothetocare-website \
                  ParameterKey=DomainName,ParameterValue='' \
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

### Option 4: Manual AWS Console Deployment

If you prefer using the AWS Console:

1. **Create S3 Bucket**:
   - Go to [S3 Console](https://console.aws.amazon.com/s3/)
   - Click "Create bucket"
   - Enter a unique bucket name
   - Choose your region
   - Click "Create bucket"

2. **Enable Static Website Hosting**:
   - Select your bucket
   - Go to "Properties" tab
   - Enable "Static website hosting"
   - Set index document to `index.html`
   - Set error document to `404.html`

3. **Block Public Access** (Important for Security):
   - Go to "Permissions" tab
   - Click "Block public access (bucket settings)"
   - Check all options (very important!)
   - Confirm changes

4. **Create CloudFormation Stack**:
   - Use template from `aws/cloudformation-template.yaml`
   - This sets up CloudFront distribution with proper security

5. **Upload Website Files**:
   - In S3 Console, upload contents of `Website/` folder
   - Or use AWS CLI: `aws s3 sync Website/ s3://bucket-name --delete`

## Deployment Flowchart

```
Start Deployment
    |
    v
Verify AWS Credentials
    |
    +---> Option 1: CloudFormation [RECOMMENDED]
    |        - More secure
    |        - CDN enabled
    |        - HTTPS ready
    |        - Better performance
    |
    +---> Option 2: Simple S3
    |        - Faster deployment
    |        - HTTP only
    |        - Not production ready
    |
    +---> Option 3: Manual CloudFormation
    |        - More control
    |        - Slower process
    |
    v
Upload Files to S3
    |
    v
Configure Cache Headers
    |
    v
✅ Website Live!
```

## What Gets Deployed

The deployment script uploads and configures:

```
Website Files:
├── index.html          → Cached for 1 hour
├── about.html          → Cached for 1 hour
├── donate.html         → Cached for 1 hour
├── contact.html        → Cached for 1 hour
├── events.html         → Cached for 1 hour
├── 404.html           → Cached for 1 hour
├── css/
│   └── style.css      → Cached for 1 year
├── js/
│   └── script.js      → Cached for 1 year
└── images/
    └── logo.jpg       → Cached for 1 year

CloudFront Distribution (CloudFormation only):
├── Origin Access Identity → Secures S3 bucket
├── Caching Policies       → Optimized TTLs
├── Security Headers       → Protection against attacks
└── HTTPS                  → Automatic encryption
```

## Testing Your Deployment

### Test Website Availability

```bash
# Get CloudFront URL
CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
  --stack-name clothetocare-website \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text)

# Test the URL
curl -I https://$CLOUDFRONT_URL
```

### Test with Different Pages

```bash
# Homepage
curl https://$CLOUDFRONT_URL

# About page
curl https://$CLOUDFRONT_URL/about.html

# Non-existent page (should return 404.html)
curl https://$CLOUDFRONT_URL/nonexistent.html
```

### Monitor CloudWatch Metrics

```bash
# Get distribution ID
DIST_ID=$(aws cloudformation describe-stacks \
  --stack-name clothetocare-website \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
  --output text)

# View recent requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$DIST_ID \
  --start-time $(date -d '1 day ago' -u +%Y-%m-%dT%H:%M:%S)Z \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S)Z \
  --period 3600 \
  --statistics Sum
```

## Post-Deployment Tasks

### 1. Set Up Custom Domain (Optional)

```bash
# Add domain parameter to CloudFormation
aws cloudformation update-stack \
  --stack-name clothetocare-website \
  --template-body file://aws/cloudformation-template.yaml \
  --parameters ParameterKey=DomainName,ParameterValue=clothetocare.org
```

### 2. Set Up SSL Certificate

Free certificates are available through AWS Certificate Manager:

```bash
# Request certificate
aws acm request-certificate \
  --domain-name clothetocare.org
```

### 3. Configure Route 53 (Optional)

Route traffic to your CloudFront distribution:

```bash
# Create DNS record pointing to CloudFront
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://dns-changes.json
```

### 4. Invalidate Cache After Updates

```bash
DIST_ID=$(aws cloudformation describe-stacks \
  --stack-name clothetocare-website \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

## Monitoring and Maintenance

### View Deployment Status

```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks \
  --stack-name clothetocare-website
```

### Monitor Website Traffic

```bash
# View CloudFront metrics
aws cloudwatch list-metrics \
  --namespace AWS/CloudFront
```

### View Recent Errors

```bash
# Check CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name clothetocare-website \
  --query 'StackEvents[?contains(LogicalResourceId, `clothetocare`)]'
```

## Troubleshooting

### Issue: Bucket name is not available

**Solution:** S3 bucket names must be globally unique. Try adding your initials or date:
- `clothetocare-website-abc-2026`
- `clothetocare-org-2026`

### Issue: CloudFormation stack creation failed

**Solution:**
1. Check the CloudFormation events: `aws cloudformation describe-stack-events --stack-name clothetocare-website`
2. Verify your AWS credentials have sufficient permissions
3. Ensure your region supports all resources

### Issue: Website shows 404 for valid pages

**Solution:**
1. Verify files were uploaded: `aws s3 ls s3://your-bucket-name/ --recursive`
2. Check CloudFront origin settings
3. Invalidate cache: `aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"`

### Issue: Old content is still showing

**Solution:** Clear CloudFront cache after updating:
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Issue: High AWS costs

**Solution:**
- Review and optimize cache TTLs
- Use CloudFront PriceClass_100 (already configured)
- Remove unused S3 versions
- Monitor data transfer
- See [AWS-BEST-PRACTICES.md](AWS-BEST-PRACTICES.md) for optimization tips

## Estimated Costs

Based on typical traffic (1,000 monthly visitors):

| Service | Monthly Cost |
|---------|-------------|
| S3 Storage | < $0.25 |
| S3 Requests | < $0.50 |
| CloudFront | < $10 |
| **Total** | **< $11/month** |

See [AWS-BEST-PRACTICES.md](AWS-BEST-PRACTICES.md) for detailed cost information.

## Before Deploying to Production

✅ Verify website works locally: `cd Website && python3 -m http.server`
✅ Test in staging environment first  
✅ Review [AWS-BEST-PRACTICES.md](AWS-BEST-PRACTICES.md)  
✅ Enable CloudWatch monitoring  
✅ Set up billing alerts  
✅ Plan for backup and disaster recovery  
✅ Review security settings  
✅ Test with actual Custom domain (if using)  
✅ Enable access logging  

## Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Pricing Calculator](https://calculator.aws/)
- **[AWS Deployment Best Practices](AWS-BEST-PRACTICES.md)** ← Read this for production deployments!

## Getting Help

If you encounter issues:

1. **Check deployment logs:**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name clothetocare-website | head -20
   ```

2. **Enable CloudFront access logs** for debugging
3. **Review S3 bucket policies** for access issues
4. **Check AWS IAM permissions** for your user

## Next Steps

After successful deployment:

1. ✅ Visit your website at the CloudFront URL
2. ✅ Verify all pages load correctly
3. ✅ Test on mobile devices
4. ✅ Set up custom domain (optional)
5. ✅ Enable CloudWatch monitoring
6. ✅ Read [AWS-BEST-PRACTICES.md](AWS-BEST-PRACTICES.md) for advanced configurations

---

**Support**: For additional help, consult the [AWS-BEST-PRACTICES.md](AWS-BEST-PRACTICES.md) guide or AWS documentation.

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
