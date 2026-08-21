# AWS Resource Checker

A comprehensive shell script to check all AWS resources across all regions.

![Screenshot](public/screenshot1.png)

## 📋 Overview

This script automatically checks various AWS resources including EC2, S3, Lambda, DynamoDB, RDS, VPC, SNS, and SQS across all AWS regions. It provides a color-coded output showing the status of each resource.

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

## 📦 Prerequisites

### 1. AWS CLI
```bash
# Fedora/RHEL/CentOS
sudo dnf install awscli

# Ubuntu/Debian
sudo apt-get install awscli

# All distributions (via pip)
pip3 install awscli --upgrade
