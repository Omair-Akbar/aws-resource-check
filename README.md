# AWS Resource Inventory Scanner

A read-only Bash script that scans AWS resources across all enabled regions and generates a detailed infrastructure inventory report.

## Features

- Scans all enabled AWS regions
- Checks resources region by region
- Generates a timestamped report
- Read-only — does not create, modify, stop, or delete resources
- Handles unavailable services or missing permissions without stopping the entire scan

### AWS Services Checked

- EC2 Instances
- EBS Volumes & Snapshots
- AMI Images
- VPCs
- Subnets
- Security Groups
- Elastic IPs
- Load Balancers
- Target Groups
- S3 Buckets
- IAM Users, Roles & Policies
- RDS Databases & Clusters
- DynamoDB
- Lambda
- ECS
- ECR
- EKS
- API Gateway
- CloudWatch Logs & Alarms
- Secrets Manager
- SSM Parameters
- Auto Scaling Groups
- Route 53
- CloudFront
- SQS
- SNS
- KMS
- ElastiCache
- Step Functions
- EventBridge

## Requirements

- Bash
- AWS CLI v2
- Configured AWS credentials
- Required AWS IAM read permissions

The script does **not** require Python, Node.js, Docker, or any additional runtime.

## Supported Linux Distributions

The script is designed for Linux systems with Bash and AWS CLI installed.

Tested/expected to work on:

- Fedora
- Ubuntu
- Debian
- Arch Linux
- Linux Mint
- RHEL
- Rocky Linux
- AlmaLinux
- openSUSE
- Amazon Linux

It should also work on other Linux distributions that provide:

- Bash
- AWS CLI
- Standard Unix utilities such as `date`, `sort`, `mkdir`, and `tee`

## AWS Authentication

Configure AWS credentials using:

```bash
aws configure
