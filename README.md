# AWS Resource Inventory Scanner

A read-only Bash script that scans AWS resources across all enabled regions and generates a detailed inventory report.

## Features

- Scans all enabled AWS regions
- Checks resources region by region
- Covers major AWS services including:
  - EC2, EBS, VPC, Subnets
  - S3, RDS, DynamoDB
  - Lambda, ECS, EKS, ECR
  - Load Balancers
  - IAM, KMS, Secrets Manager
  - CloudWatch, SQS, SNS
  - ElastiCache, Step Functions
  - Route 53, CloudFront
  - API Gateway and more
- Generates a timestamped report
- Read-only — does not create, modify, stop, or delete resources

## Requirements

- Linux
- Bash
- AWS CLI v2
- Configured AWS credentials

## Usage

```bash
chmod +x aws-resource-check.sh
./aws-resource-check.sh
