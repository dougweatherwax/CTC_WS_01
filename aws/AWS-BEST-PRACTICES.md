# AWS Deployment Best Practices for Clothe to Care

## Overview

This guide covers security, performance, and cost optimization best practices for hosting the Clothe to Care website on AWS.

## Architecture Overview

The recommended production setup includes:

```
┌─────────────────────┐
│   End Users         │
└──────────┬──────────┘
           │ (HTTPS)
    ┌──────▼──────────┐
    │   CloudFront    │
    │   (CDN)         │
    └────────┬────────┘
             │
    ┌────────▼────────────┐
    │   S3 Bucket         │
    │   (Origins)         │
    │   (Private)         │
    └─────────────────────┘
```

## 1. Security Best Practices

### 1.1 S3 Bucket Security

✅ **DO:**
- Block all public bucket access by configuring the Public Access Block
- Use CloudFront Origin Access Identity (OAI) to control access
- Enable S3 bucket versioning for recovery
- Enable S3 bucket logging
- Use server-side encryption (default: AES-256)

```bash
# Block public access
aws s3api put-public-access-block \
    --bucket clothetocare-website \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable logging
aws s3api put-bucket-logging \
    --bucket clothetocare-website \
    --bucket-logging-status file://logging.json
```

❌ **DON'T:**
- Make the bucket publicly accessible
- Use wildcards in bucket policies
- Disable encryption
- Use public bucket endpoints for production

### 1.2 CloudFront Security

✅ **DO:**
- Use CloudFront OAI (Origin Access Identity) - configured in CloudFormation template
- Enforce HTTPS only (redirect HTTP to HTTPS)
- Set appropriate cache headers
- Enable AWS WAF for additional protection (optional)
- Use security headers

❌ **DON'T:**
- Allow direct S3 website endpoint access
- Use HTTP only
- Disable origin verification

### 1.3 HTTPS/SSL Certificate

✅ **DO:**
- Use AWS Certificate Manager (ACM) for free SSL/TLS certificates
- Auto-renew certificates (ACM handles this automatically)
- Use CloudFront to serve content over HTTPS

```bash
# View your CloudFront distribution
aws cloudformation describe-stacks \
    --stack-name clothetocare-website \
    --query 'Stacks[0].Outputs'
```

## 2. Performance Optimization

### 2.1 CloudFront Caching Strategy

The deployment script automatically sets optimal cache control headers:

| File Type | Cache TTL | Strategy |
|-----------|-----------|----------|
| HTML | 1 hour | Short cache for fresh content |
| CSS/JS | 1 year | Long cache (immutable) |
| Images | 1 year | Long cache with versioning |
| API | 60 seconds | Custom per endpoint |

### 2.2 Compression

✅ CloudFront automatically compresses:
- Text files (HTML, CSS, JSON, JavaScript)
- SVG files
- Automatically does NOT compress: Pre-compressed media (JPEG, PNG, GIF)

### 2.3 Content Delivery Optimization

- **PriceClass_100**: US, Canada, Europe (recommended for cost-effective global delivery)
- **HTTP/2**: Enabled for faster multiplexed connections
- **IPv6**: Supported
- **Custom Error Pages**: 404.html configured automatically

## 3. Cost Optimization

### 3.1 Estimated Monthly Costs

For 1,000 monthly visitors (conservative estimate):

| Service | Usage | Cost |
|---------|-------|------|
| S3 Storage | ~100 MB | < $0.25 |
| S3 Requests | ~100,000 | < $0.50 |
| CloudFront (Data Out) | ~500 MB | < $10 |
| **Total** | | **< $11/month** |

### 3.2 Cost Reduction Strategies

1. **Use CloudFront PriceClass_100** (not 200 or All)
2. **Set appropriate cache headers** (reduces origin requests)
3. **Remove unused assets** from S3
4. **Monitor costs** with AWS Billing Alerts:

```bash
# Set up billing alert
aws cloudwatch put-metric-alarm \
    --alarm-name monthly-estimate \
    --alarm-description "Alert if monthly bill exceeds threshold" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 86400 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold
```

## 4. Monitoring and Maintenance

### 4.1 CloudWatch Metrics

Monitor these metrics for your distribution:

```bash
# Get CloudFront metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name Requests \
    --dimensions Name=DistributionId,Value=YOUR_DISTRIBUTION_ID \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-31T23:59:59Z \
    --period 86400 \
    --statistics Sum
```

Key metrics to monitor:
- **Requests**: Total number of requests
- **Bytes Downloaded**: Bytes served to users
- **Bytes Uploaded**: Bytes from origin to CloudFront
- **4xx/5xx Errors**: Client and server errors
- **Cache Hit Rate**: Percentage of cached vs origin requests

### 4.2 Logging

CloudFront access logs help you:
- Debug issues
- Analyze traffic patterns
- Security auditing

Enable logging in CloudFormation by adding:

```yaml
DistributionLoggingConfig:
  Bucket: my-logging-bucket.s3.amazonaws.com
  IncludeCookies: false
  Prefix: cloudfront-logs/
```

### 4.3 Cache Invalidation

After deploying updates, invalidate the CloudFront cache:

```bash
# Get Distribution ID
DIST_ID=$(aws cloudformation describe-stacks \
    --stack-name clothetocare-website \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text)

# Invalidate entire cache
aws cloudfront create-invalidation \
    --distribution-id $DIST_ID \
    --paths "/*"
```

## 5. Disaster Recovery

### 5.1 Backup Strategy

Enable S3 bucket versioning:

```bash
aws s3api put-bucket-versioning \
    --bucket clothetocare-website \
    --versioning-configuration Status=Enabled
```

### 5.2 Cross-Region Replication (Optional)

For critical websites, enable replication to another region:

```bash
# Enable replication configuration
aws s3api put-bucket-replication \
    --bucket clothetocare-website \
    --replication-configuration file://replication-config.json
```

## 6. Custom Domain Setup

### 6.1 Using Route 53 with CloudFront

1. Register domain with Route 53 or another registrar
2. Create hosted zone in Route 53
3. Add DNS record pointing to CloudFront distribution

```bash
# Create DNS record for your domain
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890ABC \
    --change-batch file://dns-change.json
```

Example `dns-change.json`:
```json
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "clothetocare.org",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2FDTNDATAQYW2",
        "DNSName": "d123.cloudfront.net",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
```

### 6.2 SSL Certificate for Custom Domain

```bash
# Request certificate for your domain
aws acm request-certificate \
    --domain-name clothetocare.org \
    --validation-method DNS

# Add CloudFront distribution alias
aws cloudformation update-stack \
    --stack-name clothetocare-website \
    --template-body file://aws/cloudformation-template.yaml \
    --parameters ParameterKey=DomainName,ParameterValue=clothetocare.org
```

## 7. Scaling Considerations

This architecture automatically scales to handle:
- **1-1,000 users**: Minimal cost, full performance
- **1,000-100,000 users**: Automatic CloudFront caching handles load
- **100,000+ users**: Maintain same performance with minimal additional cost

S3 and CloudFront automatically provide the necessary capacity without manual intervention.

## 8. Security Headers

Add these headers to your CloudFront distribution for enhanced security:

```yaml
# In CloudFormation template, add to DefaultCacheBehavior:
ResponseHeadersPolicies:
  - Id: SecurityHeadersPolicy
    ResponseHeadersPolicyConfig:
      SecurityHeadersConfig:
        StrictTransportSecurity:
          Override: false
          AccessControlMaxAgeSeconds: 63072000
          IncludeSubdomains: true
```

Or add custom headers:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

## 9. Troubleshooting

### Issue: 404 errors for subpages

**Solution:** CloudFront is configured to serve 404.html for missing objects. Ensure routing is working correctly.

### Issue: Old content showing after deployment

**Solution:** Clear CloudFront cache:
```bash
aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"
```

### Issue: High costs

**Solution:**
- Check CloudFront distribution configuration
- Verify cache TTL settings
- Monitor data transfer volumes
- Consider enabling compression

## 10. Compliance and Regulations

### Data Privacy
- **GDPR**: No personal data stored in website (stateless)
- **CCPA**: Transparent about data collection
- **HIPAA**: Not required for this use case

### Access Logs
- Enable CloudFront access logging for compliance audits
- Retain logs for minimum 90 days
- Encrypt and store logs in separate bucket

## 11. Regular Maintenance Tasks

### Daily
- Monitor CloudWatch metrics
- Check for 4xx/5xx error spikes

### Weekly
- Review CloudFront access logs
- Check AWS billing estimates

### Monthly
- Update website content
- Review and optimize cache settings
- Clean up old S3 versions (if versioning enabled)
- Update security headers and policies

### Quarterly
- Security audit of bucket policies
- Review and optimize cost
- Update CloudFormation template

## Additional Resources

- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/frontend-optimization.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Pricing Calculator](https://calculator.aws/)

## Support

For questions or issues with deployment:
1. Check CloudFormation events: `aws cloudformation describe-stack-events --stack-name clothetocare-website`
2. Review CloudFront distribution settings
3. Check S3 bucket policies and access
4. Enable CloudFront access logging for debugging
