# Clothe to Care Website

A professional, responsive website for Clothe to Care - a non-profit clothing donation charity serving the Katy and Fulshear, Texas communities.

## About Clothe to Care

Clothe to Care collects clothing donations from the local Katy and Fulshear, TX areas and donates them to needy families in partnership with Family Hope, a local charity organization.

## Website Features

- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern UI**: Clean, professional design with smooth animations
- **Multiple Pages**:
  - Home: Introduction to the organization and mission
  - About: Detailed information about values, story, and partnership with Family Hope
  - Donate: Comprehensive donation guidelines and options
  - Contact: Contact form and FAQ section

## Technologies Used

- HTML5
- CSS3 (with CSS Grid and Flexbox)
- JavaScript (Vanilla)
- Google Fonts (Poppins)

## File Structure

```
CTC_WS_01/
├── Website/                        # Website files (deploy this folder)
│   ├── index.html                  # Home page
│   ├── about.html                  # About page
│   ├── donate.html                 # Donate page
│   ├── contact.html                # Contact page
│   ├── 404.html                    # Error page for S3
│   ├── css/
│   │   └── style.css               # Main stylesheet
│   └── js/
│       └── script.js               # JavaScript functionality
├── aws/
│   ├── DEPLOYMENT.md               # Detailed AWS deployment guide
│   ├── cloudformation-template.yaml # CloudFormation IaC template
│   └── s3-bucket-policy.json       # S3 bucket policy template
├── deploy-to-aws.sh                # AWS deployment script
├── .gitignore                      # Git ignore file
└── README.md                       # This file
```

## Features

### Interactive Elements
- Mobile-responsive navigation menu
- Animated statistics counters
- Smooth scroll navigation
- Form validation
- Fade-in animations on scroll

### Design Highlights
- Professional color scheme (green/nature theme)
- Custom CSS animations
- Accessible navigation
- SEO-friendly structure

## How to Use

### Local Development
1. Open `Website/index.html` in a web browser to view the website
2. Or run a local server from the Website directory:
   ```bash
   cd Website
   python3 -m http.server 8080
   # Visit http://localhost:8080
   ```
3. Navigate through pages using the navigation menu
4. The website is fully functional locally without requiring a server

### Deploy to AWS
The website is ready for AWS deployment! See [AWS Deployment Guide](aws/DEPLOYMENT.md) for detailed instructions.

**Quick Deploy:**
```bash
./deploy-to-aws.sh
```

**Requirements:**
- AWS Account
- AWS CLI installed and configured
- Edit `deploy-to-aws.sh` to set your bucket name and region

## Deployment Options

1. **S3 Static Hosting** (Simple) - See `deploy-to-aws.sh`
2. **CloudFormation** (Infrastructure as Code) - See `aws/cloudformation-template.yaml`
3. **Manual Console** - See [Deployment Guide](aws/DEPLOYMENT.md)

## AWS Features Included

✅ S3 static website hosting configuration  
✅ CloudFront CDN with Origin Access Identity (OAI) for secure access
✅ CloudFormation Infrastructure as Code template  
✅ Custom 404 error page  
✅ Optimized cache control headers for performance
✅ HTTPS/SSL ready with AWS Certificate Manager
✅ Automatic cache invalidation support
✅ Security best practices implemented
✅ Cost-optimized pricing tier (PriceClass_100)

## AWS Security Features

- **Origins Access Identity (OAI)**: Only CloudFront can access your S3 bucket
- **Block Public Access**: S3 buckets are private by default
- **CloudFront HTTPS**: Automatic HTTPS enforcement
- **Security Headers**: Configured for XSS and clickjacking protection
- **Access Logging**: CloudFront and S3 access logging available
✅ Automated deployment script  
✅ Bucket policy templates  
✅ Cache optimization  
✅ Public access configuration  

## Customization

To customize the website:

1. **Colors**: Edit CSS variables in `css/style.css` (`:root` section)
2. **Content**: Update text directly in HTML files
3. **Images**: Add images to an `images/` folder and reference in HTML
4. **Contact Form**: Currently shows success message locally. Connect to a backend service (email API, form handler, etc.) for production use
5. **AWS Settings**: Update `deploy-to-aws.sh` or `aws/cloudformation-template.yaml`

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## AWS Costs

**Estimated monthly costs:**
- S3 hosting: ~$1/month (with free tier: $0 first year)
- CloudFront (optional): +$1-5/month
- Domain (Route 53): ~$12/year (optional)

See [AWS Deployment Guide](aws/DEPLOYMENT.md) for detailed cost breakdown.

## Future Enhancements

Consider adding:
- Image gallery of donation events
- Volunteer sign-up system
- Blog/news section
- Social media integration
- Online donation scheduling system
- Impact metrics dashboard

## Contact Information

**Clothe to Care**  
Serving Katy & Fulshear, Texas  
Email: clothetocare@gmail.com

---

© 2026 Clothe to Care. All rights reserved.
