# AWS Resource Checker - Complete Version

A comprehensive shell script to check all AWS resources across all regions.

![Screenshot](public/screenshot1.png)

## 📋 Overview

This script automatically checks **31 different AWS resource types** including EC2, S3, Lambda, DynamoDB, RDS, VPC, SNS, SQS, and many more. It provides a color-coded output showing the status of each resource across all AWS regions.

## 🖥️ Supported Linux Distributions

### ✅ Fully Tested
- **Fedora** (33+)
- **RHEL** (8+)
- **CentOS** (8+)
- **Ubuntu** (20.04+)
- **Debian** (11+)
- **AlmaLinux** (8+)
- **Rocky Linux** (8+)

### ✅ Compatible
- **Amazon Linux** 2
- **openSUSE** (15+)
- **Arch Linux** (with AUR packages)
- **SLES** (12+)

## 📦 Prerequisites

### 1. AWS CLI Installation

#### Fedora/RHEL/CentOS/AlmaLinux/Rocky
``bash
sudo dnf install awscli

Ubuntu/Debian
bash

sudo apt-get install awscli

Amazon Linux
bash

sudo yum install awscli

All Distributions (via pip)
bash

pip3 install awscli --upgrade

2. AWS Credentials Configuration
bash

aws configure

Or set environment variables:
bash

export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

3. Required IAM Permissions

The IAM user/role needs read-only permissions for:

    EC2, EBS, VPC, ELB, Auto Scaling

    S3, IAM, Route 53, CloudFront

    RDS, DynamoDB, ElastiCache

    Lambda, ECS, ECR, EKS

    API Gateway, CloudWatch, SNS, SQS

    KMS, Secrets Manager, SSM

    Step Functions, EventBridge

Example IAM Policy:
json

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "elasticloadbalancing:Describe*",
                "autoscaling:Describe*",
                "s3:List*",
                "s3:GetBucketLocation",
                "iam:List*",
                "iam:Get*",
                "rds:Describe*",
                "dynamodb:List*",
                "dynamodb:Describe*",
                "lambda:List*",
                "lambda:Get*",
                "ecs:List*",
                "ecs:Describe*",
                "ecr:Describe*",
                "eks:List*",
                "eks:Describe*",
                "apigateway:GET",
                "logs:Describe*",
                "sns:List*",
                "sqs:List*",
                "sqs:GetQueueAttributes",
                "kms:List*",
                "kms:Describe*",
                "secretsmanager:List*",
                "ssm:Describe*",
                "route53:List*",
                "cloudfront:List*",
                "elasticache:Describe*",
                "states:List*",
                "events:List*",
                "events:Describe*"
            ],
            "Resource": "*"
        }
    ]
}

🚀 Installation
Method 1: Direct Download
bash

# Download the script
curl -O https://your-server.com/aws_resource_checker.sh

# Make it executable
chmod +x aws_resource_checker.sh

Method 2: Manual Creation

    Create a new file:

bash

nano aws_resource_checker.sh

    Copy the script content and save

    Make it executable:

bash

chmod +x aws_resource_checker.sh

📊 Usage
Basic Usage
bash

./aws_resource_checker.sh

Save Output to File
bash

./aws_resource_checker.sh | tee output.log

Run in Background
bash

nohup ./aws_resource_checker.sh > check.log 2>&1 &

Quick Check (First 20 Resources)
bash

# Modify script to check only specific resources
# Edit the script and comment/uncomment resource checks

🔍 Resources Checked (31 Types)
Compute & Infrastructure
Resource	Description	Scope
EC2 Instances	Elastic Compute Cloud instances	Per Region
EBS Volumes	Elastic Block Store volumes	Per Region
EBS Snapshots	Volume snapshots	Per Region
AMI Images	Amazon Machine Images	Per Region
Auto Scaling Groups	Auto Scaling configurations	Per Region
Networking
Resource	Description	Scope
VPCs	Virtual Private Cloud	Per Region
Subnets	Network subnets	Per Region
Security Groups	Firewall rules	Per Region
Elastic IPs	Static IP addresses	Per Region
Load Balancers	ALB, NLB, Classic ELB	Per Region
Target Groups	Load balancer targets	Per Region
Route 53	DNS hosted zones	Global
CloudFront	CDN distributions	Global
API Gateway	REST and HTTP APIs	Per Region
Storage & Database
Resource	Description	Scope
S3 Buckets	Object storage	Global
RDS Databases	Relational Database Service	Per Region
RDS Clusters	Aurora clusters	Per Region
DynamoDB	NoSQL database	Per Region
ElastiCache	In-memory cache	Per Region
Container & Serverless
Resource	Description	Scope
Lambda	Serverless functions	Per Region
ECS	Container clusters	Per Region
ECR	Container repositories	Per Region
EKS	Kubernetes clusters	Per Region
Management & Security
Resource	Description	Scope
IAM Users	Identity and Access Management users	Global
IAM Roles	IAM roles	Global
IAM Policies	Custom IAM policies	Global
KMS	Key Management Service keys	Per Region
Secrets Manager	Secret storage	Per Region
SSM Parameters	Systems Manager parameters	Per Region
Monitoring & Integration
Resource	Description	Scope
CloudWatch Logs	Log groups	Per Region
CloudWatch Alarms	Metric alarms	Per Region
SNS	Notification topics	Per Region
SQS	Message queues	Per Region
Step Functions	State machines	Per Region
EventBridge	Event buses and rules	Per Region
📝 Output Legend

    🟢 Green: Resource is active and healthy

    🟡 Yellow: Resource exists but may be inactive or in non-optimal state

    🔵 Blue: Information about default or non-critical resources

    🔴 Red: Error or critical issue (especially for alarms)

    🟣 Magenta: Section headers and important information

📄 Generated Files
File	Description
aws_resource_check_YYYYMMDD_HHMMSS.log	Detailed log of all resources
aws_summary.txt	Summary of resources found by type and region
⚡ Performance Considerations
Time Estimates

    Small accounts (< 100 resources): 2-5 minutes

    Medium accounts (100-500 resources): 5-15 minutes

    Large accounts (500+ resources): 15-45 minutes

Optimizations

    The script limits output for large resource counts (e.g., first 20 IAM roles)

    API calls are made sequentially to avoid rate limiting

    Summary file provides quick overview without scrolling

🛠️ Troubleshooting
Common Issues
1. AWS CLI Not Found
bash

# Check if AWS CLI is installed
aws --version

# If not, install using appropriate method for your distribution

2. Permission Denied
bash

# Make script executable
chmod +x aws_resource_checker.sh

3. AWS Credentials Error
bash

# Verify credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure

4. Rate Limiting

If you hit AWS API rate limits:
bash

# Add delays between regions (modify script)
sleep 5  # Add after each region

5. Network Issues
bash

# Check internet connectivity
ping -c 4 aws.amazon.com

# Check AWS service health
# https://status.aws.amazon.com/

🔧 Customization
Check Specific Resources Only

Edit the script and comment/uncomment resource check functions:
bash

# In check_region_resources() function:
# check_ec2_instances "$region"  # Uncomment to check
# check_lambda "$region"         # Comment to skip

Check Specific Regions Only

Modify the regions list:
bash

# Replace get_regions function with:
REGIONS="us-east-1 us-west-2 eu-west-1"

Add Custom Tags

To filter by tags:
bash

# Modify EC2 check to filter by tags
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=Production" \
    --region "$region" ...)

📊 Sample Output
text

🚀 AWS Resource Checker - Complete Version
=========================================
🔍 Checking AWS credentials...
✅ AWS credentials verified. Account ID: 123456789012
📋 Fetching all AWS regions...
✅ Found 15 regions.

═══════════════════════════════════════════════════════════════
🌍 Checking Global Resources
═══════════════════════════════════════════════════════════════

📦 Checking S3 Buckets (Global)...
✅ my-bucket-1 (Created: 2024-01-15, Region: us-east-1)
✅ my-bucket-2 (Created: 2024-01-20, Region: eu-west-1)

👤 Checking IAM Resources (Global)...
✅ IAM Users:
  • admin-user (Created: 2024-01-01)
  • dev-user (Created: 2024-01-10)
✅ IAM Roles (first 20):
  • LambdaExecutionRole (Created: 2024-01-15)
  • EC2ReadOnlyRole (Created: 2024-01-20)

═══════════════════════════════════════════════════════════════
🌍 Checking region: us-east-1
═══════════════════════════════════════════════════════════════

📊 Checking EC2 Instances in us-east-1...
✅ i-0a1b2c3d4e5f6g7h8 (web-server) [t2.micro] - running
⏸️ i-0z9y8x7w6v5u4t3s (db-server) [t2.medium] - stopped

💾 Checking EBS Volumes in us-east-1...
✅ vol-1234567890abcdef (100GB) - in-use (AZ: us-east-1a)
📦 vol-0987654321fedcba (50GB) - available (AZ: us-east-1b)

📸 Checking EBS Snapshots in us-east-1...
✅ snap-abcdef1234567890 (100GB) - completed

🖼️ Checking AMIs in us-east-1...
✅ ami-1234567890abcdef (my-ami-v1) - available

🌐 Checking VPCs in us-east-1...
✅ vpc-12345678 (10.0.0.0/16) - Custom VPC
ℹ️ vpc-87654321 (172.31.0.0/16) - Default VPC

🔀 Checking Subnets in us-east-1...
✅ subnet-12345678 (10.0.1.0/24) - Public subnet
ℹ️ subnet-87654321 (10.0.2.0/24) - Private subnet

🛡️ Checking Security Groups in us-east-1...
✅ sg-12345678 (web-sg) - Custom SG
ℹ️ sg-87654321 (default) - Default SG

📌 Checking Elastic IPs in us-east-1...
✅ 54.123.45.67 - Associated with: i-0a1b2c3d4e5f6g7h8

⚖️ Checking Load Balancers in us-east-1...
✅ my-alb (application) - active
✅ my-nlb (network) - active

🎯 Checking Target Groups in us-east-1...
✅ web-tg (instance) - HTTP:80

🔄 Checking RDS Databases in us-east-1...
✅ my-db (postgres) - available (db.t3.micro, 20GB)

🗄️ Checking DynamoDB Tables in us-east-1...
✅ my-table - ACTIVE (Items: 1000, Size: 10MB)

⚡ Checking Lambda Functions in us-east-1...
✅ my-function (python3.9) - Active

🐳 Checking ECS Clusters in us-east-1...
✅ my-cluster - ACTIVE

☸️ Checking EKS Clusters in us-east-1...
✅ my-eks-cluster - ACTIVE

🔌 Checking API Gateway in us-east-1...
✅ REST API: my-api (abcd1234) - Created: 2024-01-15

📊 Checking CloudWatch in us-east-1...
✅ Log Groups (first 10):
  • /aws/lambda/my-function
  • /aws/ecs/my-cluster
✅ Alarm: CPU-Alarm - OK

🔐 Checking Secrets Manager in us-east-1...
✅ db-password
✅ api-key

📈 Checking Auto Scaling Groups in us-east-1...
✅ web-asg - Min:2, Max:10, Desired:2

💨 Checking ElastiCache in us-east-1...
✅ my-cache (redis) - available (cache.t2.micro)

📋 Checking Step Functions in us-east-1...
✅ order-processor (Created: 2024-01-10)

🎯 Checking EventBridge in us-east-1...
✅ Event Bus: default
✅ EventBridge Rules (first 10):
  • daily-backup-rule - ENABLED

═══════════════════════════════════════════════════════════════
✅ Resource check completed!
📄 Log file: aws_resource_check_20240115_143022.log
📊 Summary: /tmp/aws_summary.txt
═══════════════════════════════════════════════════════════════

📊 Summary of Resources Found:
Account ID: 123456789012
[Global] S3 Buckets: 5
[Global] IAM Users: 15, Roles: 23, Policies: 45
[Global] Route 53 Hosted Zones: 3
[Global] CloudFront Distributions: 2
[us-east-1] EC2 Instances: 12
[us-east-1] EBS Volumes: 25
[us-east-1] EBS Snapshots: 8
[us-east-1] AMIs: 4
[us-east-1] VPCs: 3
[us-east-1] Subnets: 12
[us-east-1] Security Groups: 18
[us-east-1] Elastic IPs: 5
[us-east-1] Load Balancers: 3
[us-east-1] Target Groups: 6
[us-east-1] RDS Instances: 4, Clusters: 2
[us-east-1] DynamoDB Tables: 7
[us-east-1] Lambda Functions: 15
[us-east-1] ECS Clusters: 3
[us-east-1] ECR Repositories: 8
[us-east-1] EKS Clusters: 1
[us-east-1] API Gateway: REST: 2, HTTP: 1
[us-east-1] CloudWatch: Log Groups: 34, Alarms: 12
[us-east-1] Secrets Manager: 6
[us-east-1] SSM Parameters: 28
[us-east-1] Auto Scaling Groups: 4
[us-east-1] SQS Queues: 15
[us-east-1] SNS Topics: 8
[us-east-1] KMS Keys: 10
[us-east-1] ElastiCache Clusters: 2
[us-east-1] Step Functions: 3
[us-east-1] EventBridge: Buses: 2, Rules: 15

📸 Screenshots

https://public/screenshot1.png

Figure 1: AWS Resource Checker running on Fedora Linux showing EC2 instances, S3 buckets, and IAM resources.
⚠️ Important Notes

    Cost Considerations: This script performs API calls that may incur minimal costs

    Permissions: Ensure IAM user has read-only permissions for all resources

    Rate Limits: AWS may throttle requests if too many API calls are made

    Large Accounts: For accounts with many resources, the script may take 15-45 minutes

    Data Privacy: No resource data is stored or transmitted - only local logging

    AWS Services: Some services may not be available in all regions

🔒 Security Best Practices

    Use Read-Only IAM Policy: Never use write permissions

    Rotate Credentials: Regularly rotate AWS access keys

    Restrict Access: Use IAM roles instead of access keys when possible

    Review Logs: Check generated logs for sensitive information

    Secure Storage: Keep log files in a secure location

📞 Support
Common Use Cases
Use Case	How to Adapt
Inventory Management	Use summary file for resource counts
Compliance Auditing	Check for public S3 buckets, open security groups
Cost Optimization	Identify stopped instances, unused volumes
Disaster Recovery	Verify backup snapshots exist
Security Assessment	Review security groups, IAM policies
Getting Help

    AWS Documentation: https://docs.aws.amazon.com/

    AWS CLI Reference: https://awscli.amazonaws.com/v2/documentation/api/latest/index.html

    AWS Status: https://status.aws.amazon.com/

📝 License

This script is provided "as-is" without warranty of any kind.

Version: 2.0.0
Last Updated: January 2024
Resources Checked: 31 AWS Services
Maintainer: AWS Resource Checker Team

Change Log:

    v2.0.0: Added 20+ new resource checks

    v1.0.0: Initial release with 11 resource checks

text


## How to Use

1. **Save the script** as `aws_resource_checker.sh`
2. **Make it executable**:
   ```bash
   chmod +x aws_resource_checker.sh

    Create the public folder:
    bash

    mkdir -p public

    Place your screenshot:
    bash

    cp your_screenshot.png public/screenshot1.png

    Run the script:
    bash

    ./aws_resource_checker.sh

The script will check all 31 resource types across all regions and generate both a detailed log and a summary file.
