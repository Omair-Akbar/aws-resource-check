#!/bin/bash

# AWS Resource Checker Script - Complete Version
# Checks all AWS resources across all regions
# Compatible with Fedora and other Linux distributions

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="aws_resource_check_$(date +%Y%m%d_%H%M%S).log"
TEMP_FILE="/tmp/aws_regions.txt"
SUMMARY_FILE="/tmp/aws_summary.txt"
ERROR_COUNT=0
SUCCESS_COUNT=0

# Initialize summary
echo "=== AWS Resource Check Summary ===" > "$SUMMARY_FILE"
echo "Run Date: $(date)" >> "$SUMMARY_FILE"
echo "=================================" >> "$SUMMARY_FILE"

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed.${NC}"
        echo "Please install AWS CLI using:"
        echo "  For Fedora: sudo dnf install awscli"
        echo "  For Ubuntu/Debian: sudo apt-get install awscli"
        echo "  Or install via pip: pip3 install awscli"
        exit 1
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    echo -e "${BLUE}🔍 Checking AWS credentials...${NC}"
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured or invalid.${NC}"
        echo "Please configure AWS credentials using:"
        echo "  aws configure"
        echo "  Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    echo -e "${GREEN}✅ AWS credentials verified. Account ID: $ACCOUNT_ID${NC}"
    echo "Account ID: $ACCOUNT_ID" >> "$SUMMARY_FILE"
}

# Function to get all AWS regions
get_regions() {
    echo -e "${BLUE}📋 Fetching all AWS regions...${NC}"
    aws ec2 describe-regions --query "Regions[].RegionName" --output text > "$TEMP_FILE"
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo -e "${RED}❌ Failed to fetch regions. Using default regions.${NC}"
        echo "us-east-1 us-east-2 us-west-1 us-west-2 eu-west-1 eu-central-1 ap-southeast-1 ap-southeast-2 ap-northeast-1 ap-northeast-2 sa-east-1" > "$TEMP_FILE"
    fi
    
    REGIONS=$(cat "$TEMP_FILE")
    echo -e "${GREEN}✅ Found $(echo $REGIONS | wc -w) regions.${NC}"
}

# ==================== RESOURCE CHECK FUNCTIONS ====================

# 1. EC2 Instances
check_ec2_instances() {
    local region=$1
    echo -e "\n${CYAN}📊 Checking EC2 Instances in $region...${NC}"
    
    INSTANCES=$(aws ec2 describe-instances --region "$region" --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType,LaunchTime,Tags[?Key=='Name']|[0].Value]" --output text 2>/dev/null)
    
    if [ -z "$INSTANCES" ]; then
        echo -e "${YELLOW}⚠️ No EC2 instances found in $region${NC}"
        echo "[$region] EC2 Instances: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$INSTANCES" | while read -r id state type launch name; do
        if [ "$state" == "running" ]; then
            echo -e "${GREEN}✅ $id ($name) [$type] - $state (Launched: $launch)${NC}"
            ((SUCCESS_COUNT++))
        elif [ "$state" == "stopped" ]; then
            echo -e "${YELLOW}⏸️ $id ($name) [$type] - $state (Launched: $launch)${NC}"
        else
            echo -e "${BLUE}ℹ️ $id ($name) [$type] - $state (Launched: $launch)${NC}"
        fi
    done
    
    COUNT=$(echo "$INSTANCES" | wc -l)
    echo "[$region] EC2 Instances: $COUNT" >> "$SUMMARY_FILE"
}

# 2. EBS Volumes
check_ebs_volumes() {
    local region=$1
    echo -e "\n${CYAN}💾 Checking EBS Volumes in $region...${NC}"
    
    VOLUMES=$(aws ec2 describe-volumes --region "$region" --query "Volumes[].[VolumeId,Size,State,AvailabilityZone,Attachments[0].InstanceId]" --output text 2>/dev/null)
    
    if [ -z "$VOLUMES" ]; then
        echo -e "${YELLOW}⚠️ No EBS volumes found in $region${NC}"
        echo "[$region] EBS Volumes: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$VOLUMES" | while read -r id size state az instance; do
        if [ "$state" == "in-use" ]; then
            echo -e "${GREEN}✅ $id (${size}GB) - $state (AZ: $az, Attached to: $instance)${NC}"
        elif [ "$state" == "available" ]; then
            echo -e "${YELLOW}📦 $id (${size}GB) - $state (AZ: $az)${NC}"
        else
            echo -e "${BLUE}ℹ️ $id (${size}GB) - $state (AZ: $az)${NC}"
        fi
    done
    
    COUNT=$(echo "$VOLUMES" | wc -l)
    echo "[$region] EBS Volumes: $COUNT" >> "$SUMMARY_FILE"
}

# 3. EBS Snapshots
check_ebs_snapshots() {
    local region=$1
    echo -e "\n${CYAN}📸 Checking EBS Snapshots in $region...${NC}"
    
    SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids "$ACCOUNT_ID" --region "$region" --query "Snapshots[].[SnapshotId,VolumeId,State,StartTime,VolumeSize]" --output text 2>/dev/null)
    
    if [ -z "$SNAPSHOTS" ]; then
        echo -e "${YELLOW}⚠️ No EBS snapshots found in $region${NC}"
        echo "[$region] EBS Snapshots: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$SNAPSHOTS" | while read -r id volume state time size; do
        if [ "$state" == "completed" ]; then
            echo -e "${GREEN}✅ $id (${size}GB) - $state (Volume: $volume)${NC}"
        else
            echo -e "${YELLOW}⏳ $id (${size}GB) - $state (Volume: $volume)${NC}"
        fi
    done
    
    COUNT=$(echo "$SNAPSHOTS" | wc -l)
    echo "[$region] EBS Snapshots: $COUNT" >> "$SUMMARY_FILE"
}

# 4. AMI Images
check_amis() {
    local region=$1
    echo -e "\n${CYAN}🖼️ Checking AMIs in $region...${NC}"
    
    AMIS=$(aws ec2 describe-images --owners self --region "$region" --query "Images[].[ImageId,Name,State,Architecture,Platform,ImageType]" --output text 2>/dev/null)
    
    if [ -z "$AMIS" ]; then
        echo -e "${YELLOW}⚠️ No AMIs found in $region${NC}"
        echo "[$region] AMIs: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$AMIS" | while read -r id name state arch platform type; do
        if [ "$state" == "available" ]; then
            echo -e "${GREEN}✅ $id ($name) - $state ($arch, ${platform:-Linux})${NC}"
        else
            echo -e "${YELLOW}⚠️ $id ($name) - $state ($arch)${NC}"
        fi
    done
    
    COUNT=$(echo "$AMIS" | wc -l)
    echo "[$region] AMIs: $COUNT" >> "$SUMMARY_FILE"
}

# 5. VPCs
check_vpcs() {
    local region=$1
    echo -e "\n${CYAN}🌐 Checking VPCs in $region...${NC}"
    
    VPCS=$(aws ec2 describe-vpcs --region "$region" --query "Vpcs[].[VpcId,CidrBlock,State,IsDefault]" --output text 2>/dev/null)
    
    if [ -z "$VPCS" ]; then
        echo -e "${YELLOW}⚠️ No VPCs found in $region${NC}"
        echo "[$region] VPCs: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$VPCS" | while read -r id cidr state is_default; do
        if [ "$is_default" == "True" ]; then
            echo -e "${BLUE}ℹ️ $id ($cidr) - Default VPC [$state]${NC}"
        else
            echo -e "${GREEN}✅ $id ($cidr) - Custom VPC [$state]${NC}"
        fi
    done
    
    COUNT=$(echo "$VPCS" | wc -l)
    echo "[$region] VPCs: $COUNT" >> "$SUMMARY_FILE"
}

# 6. Subnets
check_subnets() {
    local region=$1
    echo -e "\n${CYAN}🔀 Checking Subnets in $region...${NC}"
    
    SUBNETS=$(aws ec2 describe-subnets --region "$region" --query "Subnets[].[SubnetId,CidrBlock,VpcId,AvailabilityZone,MapPublicIpOnLaunch]" --output text 2>/dev/null)
    
    if [ -z "$SUBNETS" ]; then
        echo -e "${YELLOW}⚠️ No subnets found in $region${NC}"
        echo "[$region] Subnets: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$SUBNETS" | while read -r id cidr vpc az public; do
        if [ "$public" == "True" ]; then
            echo -e "${GREEN}✅ $id ($cidr) - Public subnet (AZ: $az, VPC: $vpc)${NC}"
        else
            echo -e "${BLUE}ℹ️ $id ($cidr) - Private subnet (AZ: $az, VPC: $vpc)${NC}"
        fi
    done
    
    COUNT=$(echo "$SUBNETS" | wc -l)
    echo "[$region] Subnets: $COUNT" >> "$SUMMARY_FILE"
}

# 7. Security Groups
check_security_groups() {
    local region=$1
    echo -e "\n${CYAN}🛡️ Checking Security Groups in $region...${NC}"
    
    SGS=$(aws ec2 describe-security-groups --region "$region" --query "SecurityGroups[].[GroupId,GroupName,VpcId,Description]" --output text 2>/dev/null)
    
    if [ -z "$SGS" ]; then
        echo -e "${YELLOW}⚠️ No security groups found in $region${NC}"
        echo "[$region] Security Groups: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$SGS" | while read -r id name vpc desc; do
        if [[ "$name" == "default" ]]; then
            echo -e "${BLUE}ℹ️ $id ($name) - Default SG (VPC: $vpc)${NC}"
        else
            echo -e "${GREEN}✅ $id ($name) - Custom SG (VPC: $vpc)${NC}"
        fi
    done
    
    COUNT=$(echo "$SGS" | wc -l)
    echo "[$region] Security Groups: $COUNT" >> "$SUMMARY_FILE"
}

# 8. Elastic IPs
check_elastic_ips() {
    local region=$1
    echo -e "\n${CYAN}📌 Checking Elastic IPs in $region...${NC}"
    
    EIPS=$(aws ec2 describe-addresses --region "$region" --query "Addresses[].[PublicIp,AllocationId,InstanceId,AssociationId]" --output text 2>/dev/null)
    
    if [ -z "$EIPS" ]; then
        echo -e "${YELLOW}⚠️ No Elastic IPs found in $region${NC}"
        echo "[$region] Elastic IPs: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$EIPS" | while read -r ip allocid instance associd; do
        if [ "$instance" != "None" ] && [ -n "$instance" ]; then
            echo -e "${GREEN}✅ $ip - Associated with: $instance${NC}"
        else
            echo -e "${YELLOW}⚠️ $ip - Unassociated${NC}"
        fi
    done
    
    COUNT=$(echo "$EIPS" | wc -l)
    echo "[$region] Elastic IPs: $COUNT" >> "$SUMMARY_FILE"
}

# 9. Load Balancers
check_load_balancers() {
    local region=$1
    echo -e "\n${CYAN}⚖️ Checking Load Balancers in $region...${NC}"
    
    # ALB/NLB
    LBS=$(aws elbv2 describe-load-balancers --region "$region" --query "LoadBalancers[].[LoadBalancerName,DNSName,Type,State.Code,VpcId]" --output text 2>/dev/null)
    
    # Classic ELB
    CLASSIC_LBS=$(aws elb describe-load-balancers --region "$region" --query "LoadBalancerDescriptions[].[LoadBalancerName,DNSName,AvailabilityZones[0]]" --output text 2>/dev/null)
    
    if [ -z "$LBS" ] && [ -z "$CLASSIC_LBS" ]; then
        echo -e "${YELLOW}⚠️ No load balancers found in $region${NC}"
        echo "[$region] Load Balancers: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    if [ -n "$LBS" ]; then
        echo "$LBS" | while read -r name dns type state vpc; do
            if [ "$state" == "active" ]; then
                echo -e "${GREEN}✅ $name ($type) - $state (DNS: $dns)${NC}"
            else
                echo -e "${YELLOW}⚠️ $name ($type) - $state (DNS: $dns)${NC}"
            fi
        done
    fi
    
    if [ -n "$CLASSIC_LBS" ]; then
        echo "$CLASSIC_LBS" | while read -r name dns az; do
            echo -e "${GREEN}✅ $name (Classic) - Active (AZ: $az)${NC}"
        done
    fi
    
    COUNT=$(($(echo "$LBS" | wc -l) + $(echo "$CLASSIC_LBS" | wc -l)))
    echo "[$region] Load Balancers: $COUNT" >> "$SUMMARY_FILE"
}

# 10. Target Groups
check_target_groups() {
    local region=$1
    echo -e "\n${CYAN}🎯 Checking Target Groups in $region...${NC}"
    
    TGS=$(aws elbv2 describe-target-groups --region "$region" --query "TargetGroups[].[TargetGroupName,TargetType,Protocol,Port,VpcId]" --output text 2>/dev/null)
    
    if [ -z "$TGS" ]; then
        echo -e "${YELLOW}⚠️ No target groups found in $region${NC}"
        echo "[$region] Target Groups: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$TGS" | while read -r name type protocol port vpc; do
        echo -e "${GREEN}✅ $name ($type) - $protocol:$port (VPC: $vpc)${NC}"
    done
    
    COUNT=$(echo "$TGS" | wc -l)
    echo "[$region] Target Groups: $COUNT" >> "$SUMMARY_FILE"
}

# 11. S3 Buckets (Global)
check_s3_buckets() {
    echo -e "\n${CYAN}📦 Checking S3 Buckets (Global)...${NC}"
    
    BUCKETS=$(aws s3api list-buckets --query "Buckets[].[Name,CreationDate]" --output text 2>/dev/null)
    
    if [ -z "$BUCKETS" ]; then
        echo -e "${YELLOW}⚠️ No S3 buckets found.${NC}"
        echo "[Global] S3 Buckets: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$BUCKETS" | while read -r name date; do
        # Get bucket region
        bucket_region=$(aws s3api get-bucket-location --bucket "$name" --query "LocationConstraint" --output text 2>/dev/null)
        if [ -z "$bucket_region" ] || [ "$bucket_region" == "None" ]; then
            bucket_region="us-east-1"
        fi
        
        # Check if bucket is public
        public=$(aws s3api get-bucket-acl --bucket "$name" --query "Grants[?Grantee.URI=='http://acs.amazonaws.com/groups/global/AllUsers']" --output text 2>/dev/null)
        
        if [ -n "$public" ]; then
            echo -e "${YELLOW}⚠️ $name (Created: $date, Region: $bucket_region) - PUBLIC${NC}"
        else
            echo -e "${GREEN}✅ $name (Created: $date, Region: $bucket_region)${NC}"
        fi
    done
    
    COUNT=$(echo "$BUCKETS" | wc -l)
    echo "[Global] S3 Buckets: $COUNT" >> "$SUMMARY_FILE"
}

# 12. IAM Users, Roles & Policies (Global)
check_iam() {
    echo -e "\n${CYAN}👤 Checking IAM Resources (Global)...${NC}"
    
    # Users
    USERS=$(aws iam list-users --query "Users[].[UserName,UserId,CreateDate]" --output text 2>/dev/null)
    if [ -n "$USERS" ]; then
        echo -e "${GREEN}✅ IAM Users:${NC}"
        echo "$USERS" | while read -r name id created; do
            echo -e "  ${GREEN}• $name (Created: $created)${NC}"
        done
        USER_COUNT=$(echo "$USERS" | wc -l)
    else
        USER_COUNT=0
    fi
    
    # Roles
    ROLES=$(aws iam list-roles --query "Roles[].[RoleName,RoleId,CreateDate]" --output text 2>/dev/null | head -20)
    if [ -n "$ROLES" ]; then
        echo -e "${GREEN}✅ IAM Roles (first 20):${NC}"
        echo "$ROLES" | while read -r name id created; do
            echo -e "  ${GREEN}• $name (Created: $created)${NC}"
        done
        ROLE_COUNT=$(aws iam list-roles --query "Roles[].[RoleName]" --output text 2>/dev/null | wc -l)
    else
        ROLE_COUNT=0
    fi
    
    # Policies (custom)
    POLICIES=$(aws iam list-policies --scope Local --query "Policies[].[PolicyName,PolicyId,CreateDate]" --output text 2>/dev/null | head -20)
    if [ -n "$POLICIES" ]; then
        echo -e "${GREEN}✅ IAM Policies (custom, first 20):${NC}"
        echo "$POLICIES" | while read -r name id created; do
            echo -e "  ${GREEN}• $name (Created: $created)${NC}"
        done
        POLICY_COUNT=$(aws iam list-policies --scope Local --query "Policies[].[PolicyName]" --output text 2>/dev/null | wc -l)
    else
        POLICY_COUNT=0
    fi
    
    echo "[Global] IAM Users: $USER_COUNT, Roles: $ROLE_COUNT, Policies: $POLICY_COUNT" >> "$SUMMARY_FILE"
}

# 13. RDS Databases & Clusters
check_rds() {
    local region=$1
    echo -e "\n${CYAN}🔄 Checking RDS Databases in $region...${NC}"
    
    # RDS Instances
    INSTANCES=$(aws rds describe-db-instances --region "$region" --query "DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus,AllocatedStorage]" --output text 2>/dev/null)
    
    if [ -n "$INSTANCES" ]; then
        echo "$INSTANCES" | while read -r id class engine status storage; do
            if [ "$status" == "available" ]; then
                echo -e "${GREEN}✅ Instance: $id ($engine) - $status (Class: $class, Storage: ${storage}GB)${NC}"
            else
                echo -e "${YELLOW}⚠️ Instance: $id ($engine) - $status (Class: $class)${NC}"
            fi
        done
        INSTANCE_COUNT=$(echo "$INSTANCES" | wc -l)
    else
        INSTANCE_COUNT=0
    fi
    
    # RDS Clusters (Aurora)
    CLUSTERS=$(aws rds describe-db-clusters --region "$region" --query "DBClusters[].[DBClusterIdentifier,Engine,Status]" --output text 2>/dev/null)
    
    if [ -n "$CLUSTERS" ]; then
        echo "$CLUSTERS" | while read -r id engine status; do
            if [ "$status" == "available" ]; then
                echo -e "${GREEN}✅ Cluster: $id ($engine) - $status${NC}"
            else
                echo -e "${YELLOW}⚠️ Cluster: $id ($engine) - $status${NC}"
            fi
        done
        CLUSTER_COUNT=$(echo "$CLUSTERS" | wc -l)
    else
        CLUSTER_COUNT=0
    fi
    
    echo "[$region] RDS Instances: $INSTANCE_COUNT, Clusters: $CLUSTER_COUNT" >> "$SUMMARY_FILE"
}

# 14. DynamoDB
check_dynamodb() {
    local region=$1
    echo -e "\n${CYAN}🗄️ Checking DynamoDB Tables in $region...${NC}"
    
    TABLES=$(aws dynamodb list-tables --region "$region" --query "TableNames[]" --output text 2>/dev/null)
    
    if [ -z "$TABLES" ]; then
        echo -e "${YELLOW}⚠️ No DynamoDB tables found in $region${NC}"
        echo "[$region] DynamoDB: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    for table in $TABLES; do
        table_info=$(aws dynamodb describe-table --table-name "$table" --region "$region" --query "Table.[TableStatus,ItemCount,TableSizeBytes]" --output text 2>/dev/null)
        if [ -n "$table_info" ]; then
            status=$(echo "$table_info" | awk '{print $1}')
            items=$(echo "$table_info" | awk '{print $2}')
            size=$(echo "$table_info" | awk '{print $3}')
            
            if [ "$status" == "ACTIVE" ]; then
                echo -e "${GREEN}✅ $table - $status (Items: $items, Size: $(($size/1024/1024))MB)${NC}"
            else
                echo -e "${YELLOW}⚠️ $table - $status (Items: $items)${NC}"
            fi
        fi
    done
    
    COUNT=$(echo "$TABLES" | wc -w)
    echo "[$region] DynamoDB Tables: $COUNT" >> "$SUMMARY_FILE"
}

# 15. Lambda
check_lambda() {
    local region=$1
    echo -e "\n${CYAN}⚡ Checking Lambda Functions in $region...${NC}"
    
    FUNCTIONS=$(aws lambda list-functions --region "$region" --query "Functions[].[FunctionName,Runtime,LastModified,State]" --output text 2>/dev/null)
    
    if [ -z "$FUNCTIONS" ]; then
        echo -e "${YELLOW}⚠️ No Lambda functions found in $region${NC}"
        echo "[$region] Lambda: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$FUNCTIONS" | while read -r name runtime modified state; do
        if [ "$state" == "Active" ]; then
            echo -e "${GREEN}✅ $name ($runtime) - Active (Modified: $modified)${NC}"
        else
            echo -e "${YELLOW}⚠️ $name ($runtime) - $state (Modified: $modified)${NC}"
        fi
    done
    
    COUNT=$(echo "$FUNCTIONS" | wc -l)
    echo "[$region] Lambda Functions: $COUNT" >> "$SUMMARY_FILE"
}

# 16. ECS
check_ecs() {
    local region=$1
    echo -e "\n${CYAN}🐳 Checking ECS Clusters in $region...${NC}"
    
    CLUSTERS=$(aws ecs list-clusters --region "$region" --query "clusterArns[]" --output text 2>/dev/null)
    
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠️ No ECS clusters found in $region${NC}"
        echo "[$region] ECS: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    for cluster in $CLUSTERS; do
        cluster_name=$(echo "$cluster" | awk -F/ '{print $NF}')
        # Get cluster status
        status=$(aws ecs describe-clusters --clusters "$cluster_name" --region "$region" --query "clusters[0].status" --output text 2>/dev/null)
        if [ "$status" == "ACTIVE" ]; then
            echo -e "${GREEN}✅ $cluster_name - $status${NC}"
        else
            echo -e "${YELLOW}⚠️ $cluster_name - $status${NC}"
        fi
    done
    
    COUNT=$(echo "$CLUSTERS" | wc -w)
    echo "[$region] ECS Clusters: $COUNT" >> "$SUMMARY_FILE"
}

# 17. ECR
check_ecr() {
    local region=$1
    echo -e "\n${CYAN}📦 Checking ECR Repositories in $region...${NC}"
    
    REPOS=$(aws ecr describe-repositories --region "$region" --query "repositories[].[repositoryName,repositoryUri]" --output text 2>/dev/null)
    
    if [ -z "$REPOS" ]; then
        echo -e "${YELLOW}⚠️ No ECR repositories found in $region${NC}"
        echo "[$region] ECR: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$REPOS" | while read -r name uri; do
        echo -e "${GREEN}✅ $name (URI: $uri)${NC}"
    done
    
    COUNT=$(echo "$REPOS" | wc -l)
    echo "[$region] ECR Repositories: $COUNT" >> "$SUMMARY_FILE"
}

# 18. EKS
check_eks() {
    local region=$1
    echo -e "\n${CYAN}☸️ Checking EKS Clusters in $region...${NC}"
    
    CLUSTERS=$(aws eks list-clusters --region "$region" --query "clusters[]" --output text 2>/dev/null)
    
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠️ No EKS clusters found in $region${NC}"
        echo "[$region] EKS: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    for cluster in $CLUSTERS; do
        status=$(aws eks describe-cluster --name "$cluster" --region "$region" --query "cluster.status" --output text 2>/dev/null)
        if [ "$status" == "ACTIVE" ]; then
            echo -e "${GREEN}✅ $cluster - $status${NC}"
        else
            echo -e "${YELLOW}⚠️ $cluster - $status${NC}"
        fi
    done
    
    COUNT=$(echo "$CLUSTERS" | wc -w)
    echo "[$region] EKS Clusters: $COUNT" >> "$SUMMARY_FILE"
}

# 19. API Gateway
check_api_gateway() {
    local region=$1
    echo -e "\n${CYAN}🔌 Checking API Gateway in $region...${NC}"
    
    # REST APIs
    REST_APIS=$(aws apigateway get-rest-apis --region "$region" --query "items[].[name,id,createdDate]" --output text 2>/dev/null)
    if [ -n "$REST_APIS" ]; then
        echo "$REST_APIS" | while read -r name id created; do
            echo -e "${GREEN}✅ REST API: $name ($id) - Created: $created${NC}"
        done
        REST_COUNT=$(echo "$REST_APIS" | wc -l)
    else
        REST_COUNT=0
    fi
    
    # HTTP APIs
    HTTP_APIS=$(aws apigatewayv2 get-apis --region "$region" --query "Items[].[Name,ApiId,CreatedDate]" --output text 2>/dev/null)
    if [ -n "$HTTP_APIS" ]; then
        echo "$HTTP_APIS" | while read -r name id created; do
            echo -e "${GREEN}✅ HTTP API: $name ($id) - Created: $created${NC}"
        done
        HTTP_COUNT=$(echo "$HTTP_APIS" | wc -l)
    else
        HTTP_COUNT=0
    fi
    
    TOTAL=$((REST_COUNT + HTTP_COUNT))
    echo "[$region] API Gateway: REST: $REST_COUNT, HTTP: $HTTP_COUNT" >> "$SUMMARY_FILE"
}

# 20. CloudWatch Logs & Alarms
check_cloudwatch() {
    local region=$1
    echo -e "\n${CYAN}📊 Checking CloudWatch in $region...${NC}"
    
    # Log Groups
    LOG_GROUPS=$(aws logs describe-log-groups --region "$region" --query "logGroups[].logGroupName" --output text 2>/dev/null | head -10)
    if [ -n "$LOG_GROUPS" ]; then
        echo -e "${GREEN}✅ Log Groups (first 10):${NC}"
        echo "$LOG_GROUPS" | while read -r name; do
            echo -e "  ${GREEN}• $name${NC}"
        done
        LOG_COUNT=$(aws logs describe-log-groups --region "$region" --query "length(logGroups)" --output text 2>/dev/null)
    else
        LOG_COUNT=0
    fi
    
    # Alarms
    ALARMS=$(aws cloudwatch describe-alarms --region "$region" --query "MetricAlarms[].[AlarmName,StateValue]" --output text 2>/dev/null)
    if [ -n "$ALARMS" ]; then
        echo "$ALARMS" | while read -r name state; do
            if [ "$state" == "OK" ]; then
                echo -e "${GREEN}✅ Alarm: $name - $state${NC}"
            elif [ "$state" == "ALARM" ]; then
                echo -e "${RED}🔴 Alarm: $name - $state${NC}"
            else
                echo -e "${YELLOW}⚠️ Alarm: $name - $state${NC}"
            fi
        done
        ALARM_COUNT=$(echo "$ALARMS" | wc -l)
    else
        ALARM_COUNT=0
    fi
    
    echo "[$region] CloudWatch: Log Groups: $LOG_COUNT, Alarms: $ALARM_COUNT" >> "$SUMMARY_FILE"
}

# 21. Secrets Manager
check_secrets_manager() {
    local region=$1
    echo -e "\n${CYAN}🔐 Checking Secrets Manager in $region...${NC}"
    
    SECRETS=$(aws secretsmanager list-secrets --region "$region" --query "SecretList[].[Name,SecretArn]" --output text 2>/dev/null)
    
    if [ -z "$SECRETS" ]; then
        echo -e "${YELLOW}⚠️ No secrets found in $region${NC}"
        echo "[$region] Secrets Manager: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$SECRETS" | while read -r name arn; do
        echo -e "${GREEN}✅ $name${NC}"
    done
    
    COUNT=$(echo "$SECRETS" | wc -l)
    echo "[$region] Secrets Manager: $COUNT" >> "$SUMMARY_FILE"
}

# 22. SSM Parameters
check_ssm_parameters() {
    local region=$1
    echo -e "\n${CYAN}⚙️ Checking SSM Parameters in $region...${NC}"
    
    PARAMS=$(aws ssm describe-parameters --region "$region" --query "Parameters[].Name" --output text 2>/dev/null | head -10)
    
    if [ -z "$PARAMS" ]; then
        echo -e "${YELLOW}⚠️ No SSM parameters found in $region${NC}"
        echo "[$region] SSM Parameters: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo -e "${GREEN}✅ SSM Parameters (first 10):${NC}"
    echo "$PARAMS" | while read -r name; do
        echo -e "  ${GREEN}• $name${NC}"
    done
    
    COUNT=$(aws ssm describe-parameters --region "$region" --query "length(Parameters)" --output text 2>/dev/null)
    echo "[$region] SSM Parameters: $COUNT" >> "$SUMMARY_FILE"
}

# 23. Auto Scaling Groups
check_auto_scaling() {
    local region=$1
    echo -e "\n${CYAN}📈 Checking Auto Scaling Groups in $region...${NC}"
    
    ASGS=$(aws autoscaling describe-auto-scaling-groups --region "$region" --query "AutoScalingGroups[].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity,LaunchConfigurationName]" --output text 2>/dev/null)
    
    if [ -z "$ASGS" ]; then
        echo -e "${YELLOW}⚠️ No Auto Scaling groups found in $region${NC}"
        echo "[$region] Auto Scaling: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$ASGS" | while read -r name min max desired launch; do
        echo -e "${GREEN}✅ $name - Min:$min, Max:$max, Desired:$desired${NC}"
    done
    
    COUNT=$(echo "$ASGS" | wc -l)
    echo "[$region] Auto Scaling Groups: $COUNT" >> "$SUMMARY_FILE"
}

# 24. Route 53 (Global)
check_route53() {
    echo -e "\n${CYAN}🌍 Checking Route 53 (Global)...${NC}"
    
    HOSTED_ZONES=$(aws route53 list-hosted-zones --query "HostedZones[].[Name,Id]" --output text 2>/dev/null)
    
    if [ -z "$HOSTED_ZONES" ]; then
        echo -e "${YELLOW}⚠️ No Route 53 hosted zones found${NC}"
        echo "[Global] Route 53: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$HOSTED_ZONES" | while read -r name id; do
        echo -e "${GREEN}✅ $name ($id)${NC}"
    done
    
    COUNT=$(echo "$HOSTED_ZONES" | wc -l)
    echo "[Global] Route 53 Hosted Zones: $COUNT" >> "$SUMMARY_FILE"
}

# 25. CloudFront (Global)
check_cloudfront() {
    echo -e "\n${CYAN}🌩️ Checking CloudFront (Global)...${NC}"
    
    DISTRIBUTIONS=$(aws cloudfront list-distributions --query "DistributionList.Items[].[Id,Status,Enabled,DomainName]" --output text 2>/dev/null)
    
    if [ -z "$DISTRIBUTIONS" ]; then
        echo -e "${YELLOW}⚠️ No CloudFront distributions found${NC}"
        echo "[Global] CloudFront: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$DISTRIBUTIONS" | while read -r id status enabled domain; do
        if [ "$enabled" == "True" ]; then
            echo -e "${GREEN}✅ $id - Enabled (Domain: $domain)${NC}"
        else
            echo -e "${YELLOW}⚠️ $id - Disabled (Domain: $domain)${NC}"
        fi
    done
    
    COUNT=$(echo "$DISTRIBUTIONS" | wc -l)
    echo "[Global] CloudFront Distributions: $COUNT" >> "$SUMMARY_FILE"
}

# 26. SQS
check_sqs() {
    local region=$1
    echo -e "\n${CYAN}📬 Checking SQS Queues in $region...${NC}"
    
    QUEUES=$(aws sqs list-queues --region "$region" --query "QueueUrls[]" --output text 2>/dev/null)
    
    if [ -z "$QUEUES" ]; then
        echo -e "${YELLOW}⚠️ No SQS queues found in $region${NC}"
        echo "[$region] SQS: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    for queue in $QUEUES; do
        queue_name=$(echo "$queue" | awk -F/ '{print $NF}')
        # Get queue attributes
        attrs=$(aws sqs get-queue-attributes --queue-url "$queue" --attribute-names ApproximateNumberOfMessages --region "$region" --query "Attributes.ApproximateNumberOfMessages" --output text 2>/dev/null)
        echo -e "${GREEN}✅ $queue_name (Messages: $attrs)${NC}"
    done
    
    COUNT=$(echo "$QUEUES" | wc -w)
    echo "[$region] SQS Queues: $COUNT" >> "$SUMMARY_FILE"
}

# 27. SNS
check_sns() {
    local region=$1
    echo -e "\n${CYAN}📨 Checking SNS Topics in $region...${NC}"
    
    TOPICS=$(aws sns list-topics --region "$region" --query "Topics[].[TopicArn]" --output text 2>/dev/null)
    
    if [ -z "$TOPICS" ]; then
        echo -e "${YELLOW}⚠️ No SNS topics found in $region${NC}"
        echo "[$region] SNS: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    for topic in $TOPICS; do
        topic_name=$(echo "$topic" | awk -F: '{print $NF}')
        echo -e "${GREEN}✅ $topic_name${NC}"
    done
    
    COUNT=$(echo "$TOPICS" | wc -l)
    echo "[$region] SNS Topics: $COUNT" >> "$SUMMARY_FILE"
}

# 28. KMS
check_kms() {
    local region=$1
    echo -e "\n${CYAN}🔑 Checking KMS Keys in $region...${NC}"
    
    KEYS=$(aws kms list-keys --region "$region" --query "Keys[].[KeyId]" --output text 2>/dev/null | head -10)
    
    if [ -z "$KEYS" ]; then
        echo -e "${YELLOW}⚠️ No KMS keys found in $region${NC}"
        echo "[$region] KMS: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo -e "${GREEN}✅ KMS Keys (first 10):${NC}"
    for key in $KEYS; do
        # Get key state
        state=$(aws kms describe-key --key-id "$key" --region "$region" --query "KeyMetadata.KeyState" --output text 2>/dev/null)
        echo -e "  ${GREEN}• $key ($state)${NC}"
    done
    
    COUNT=$(aws kms list-keys --region "$region" --query "length(Keys)" --output text 2>/dev/null)
    echo "[$region] KMS Keys: $COUNT" >> "$SUMMARY_FILE"
}

# 29. ElastiCache
check_elasticache() {
    local region=$1
    echo -e "\n${CYAN}💨 Checking ElastiCache in $region...${NC}"
    
    # Cache Clusters
    CLUSTERS=$(aws elasticache describe-cache-clusters --region "$region" --query "CacheClusters[].[CacheClusterId,CacheNodeType,Engine,CacheClusterStatus]" --output text 2>/dev/null)
    
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠️ No ElastiCache clusters found in $region${NC}"
        echo "[$region] ElastiCache: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$CLUSTERS" | while read -r id node_type engine status; do
        if [ "$status" == "available" ]; then
            echo -e "${GREEN}✅ $id ($engine) - $status (Node: $node_type)${NC}"
        else
            echo -e "${YELLOW}⚠️ $id ($engine) - $status (Node: $node_type)${NC}"
        fi
    done
    
    COUNT=$(echo "$CLUSTERS" | wc -l)
    echo "[$region] ElastiCache Clusters: $COUNT" >> "$SUMMARY_FILE"
}

# 30. Step Functions
check_step_functions() {
    local region=$1
    echo -e "\n${CYAN}📋 Checking Step Functions in $region...${NC}"
    
    MACHINES=$(aws stepfunctions list-state-machines --region "$region" --query "stateMachines[].[name,stateMachineArn,creationDate]" --output text 2>/dev/null)
    
    if [ -z "$MACHINES" ]; then
        echo -e "${YELLOW}⚠️ No Step Functions found in $region${NC}"
        echo "[$region] Step Functions: 0" >> "$SUMMARY_FILE"
        return
    fi
    
    echo "$MACHINES" | while read -r name arn created; do
        echo -e "${GREEN}✅ $name (Created: $created)${NC}"
    done
    
    COUNT=$(echo "$MACHINES" | wc -l)
    echo "[$region] Step Functions: $COUNT" >> "$SUMMARY_FILE"
}

# 31. EventBridge
check_eventbridge() {
    local region=$1
    echo -e "\n${CYAN}🎯 Checking EventBridge in $region...${NC}"
    
    # Event buses
    BUSES=$(aws events list-event-buses --region "$region" --query "EventBuses[].[Name,Arn]" --output text 2>/dev/null)
    if [ -n "$BUSES" ]; then
        echo "$BUSES" | while read -r name arn; do
            echo -e "${GREEN}✅ Event Bus: $name${NC}"
        done
        BUS_COUNT=$(echo "$BUSES" | wc -l)
    else
        BUS_COUNT=0
    fi
    
    # Rules
    RULES=$(aws events list-rules --region "$region" --query "Rules[].[Name,State,Description]" --output text 2>/dev/null | head -10)
    if [ -n "$RULES" ]; then
        echo -e "${GREEN}✅ EventBridge Rules (first 10):${NC}"
        echo "$RULES" | while read -r name state desc; do
            echo -e "  ${GREEN}• $name - $state${NC}"
        done
        RULE_COUNT=$(aws events list-rules --region "$region" --query "length(Rules)" --output text 2>/dev/null)
    else
        RULE_COUNT=0
    fi
    
    echo "[$region] EventBridge: Buses: $BUS_COUNT, Rules: $RULE_COUNT" >> "$SUMMARY_FILE"
}

# ==================== REGION PROCESSING ====================

# Main function to check all resources in a region
check_region_resources() {
    local region=$1
    echo -e "\n${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}🌍 Checking region: $region${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    
    # EC2 Resources
    check_ec2_instances "$region"
    check_ebs_volumes "$region"
    check_ebs_snapshots "$region"
    check_amis "$region"
    check_vpcs "$region"
    check_subnets "$region"
    check_security_groups "$region"
    check_elastic_ips "$region"
    check_load_balancers "$region"
    check_target_groups "$region"
    
    # Database
    check_rds "$region"
    check_dynamodb "$region"
    check_elasticache "$region"
    
    # Compute & Container
    check_lambda "$region"
    check_ecs "$region"
    check_ecr "$region"
    check_eks "$region"
    
    # Networking
    check_api_gateway "$region"
    check_sqs "$region"
    check_sns "$region"
    
    # Management & Security
    check_cloudwatch "$region"
    check_secrets_manager "$region"
    check_ssm_parameters "$region"
    check_auto_scaling "$region"
    check_kms "$region"
    check_step_functions "$region"
    check_eventbridge "$region"
}

# ==================== MAIN EXECUTION ====================

main() {
    echo -e "${MAGENTA}🚀 AWS Resource Checker - Complete Version${NC}"
    echo -e "${MAGENTA}=========================================${NC}"
    
    # Check prerequisites
    check_aws_cli
    check_aws_credentials
    
    # Get all regions
    get_regions
    
    # Global Resources
    echo -e "\n${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}🌍 Checking Global Resources${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    
    check_s3_buckets
    check_iam
    check_route53
    check_cloudfront
    
    # Loop through each region
    for region in $REGIONS; do
        check_region_resources "$region"
    done
    
    # Summary
    echo -e "\n${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Resource check completed!${NC}"
    echo -e "${BLUE}📄 Log file: $LOG_FILE${NC}"
    echo -e "${BLUE}📊 Summary: $SUMMARY_FILE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    
    # Display summary
    echo -e "\n${GREEN}📊 Summary of Resources Found:${NC}"
    cat "$SUMMARY_FILE"
    
    # Cleanup
    rm -f "$TEMP_FILE"
}

# Run the main function
main
