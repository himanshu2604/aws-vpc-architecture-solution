#!/bin/bash

# AWS VPC Multi-Tier Architecture - Production VPC Setup
# Creates Production VPC with 4-tier architecture (Web, App1, App2, Cache, DB)

set -e  # Exit on any error

# Configuration Variables
VPC_NAME="Production-VPC"
VPC_CIDR="10.0.0.0/16"
REGION="us-east-1"
AZ_A="us-east-1a"
AZ_B="us-east-1b"

echo "🏗️ Setting up Production VPC..."

# Create VPC
echo "📊 Creating Production VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" \
    --query 'Vpc.VpcId' \
    --output text)

echo "✅ VPC Created: $VPC_ID"

# Enable DNS hostname and resolution
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# Create Internet Gateway
echo "🌐 Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Production-IGW}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "✅ Internet Gateway Created and Attached: $IGW_ID"

# Create Subnets
echo "📍 Creating Subnets..."

# Web Subnet (Public)
WEB_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.0.1.0/24" \
    --availability-zone $AZ_A \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=web}]" \
    --query 'Subnet.SubnetId' \
    --output text)

# App1 Subnet (Private with NAT)
APP1_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.0.2.0/24" \
    --availability-zone $AZ_A \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=app1}]" \
    --query 'Subnet.SubnetId' \
    --output text)

# App2 Subnet (Private isolated)
APP2_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.0.3.0/24" \
    --availability-zone $AZ_B \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=app2}]" \
    --query 'Subnet.SubnetId' \
    --output text)

# DBCache Subnet (Private with NAT)
DBCACHE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.0.4.0/24" \
    --availability-zone $AZ_A \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=dbcache}]" \
    --query 'Subnet.SubnetId' \
    --output text)

# DB Subnet (Private isolated)
DB_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.0.5.0/24" \
    --availability-zone $AZ_B \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=db}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "✅ Subnets Created:"
echo "   Web: $WEB_SUBNET_ID"
echo "   App1: $APP1_SUBNET_ID"
echo "   App2: $APP2_SUBNET_ID"
echo "   DBCache: $DBCACHE_SUBNET_ID"
echo "   DB: $DB_SUBNET_ID"

# Enable auto-assign public IP for web subnet
aws ec2 modify-subnet-attribute --subnet-id $WEB_SUBNET_ID --map-public-ip-on-launch

# Create NAT Gateway
echo "🔄 Creating NAT Gateway..."
# Allocate Elastic IP
EIP_ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Create NAT Gateway in web subnet
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $WEB_SUBNET_ID \
    --allocation-id $EIP_ALLOCATION_ID \
    --tag-specifications "ResourceType=nat-gateway,Tags=[{Key=Name,Value=Production-NAT}]" \
    --query 'NatGateway.NatGatewayId' \
    --output text)

echo "✅ NAT Gateway Created: $NAT_GW_ID"
echo "⏳ Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

# Create Route Tables
echo "🛣️ Creating Route Tables..."

# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-Public-RT}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Private Route Table (with NAT)
PRIVATE_NAT_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-Private-NAT-RT}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Private Route Table (isolated)
PRIVATE_ISOLATED_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Production-Private-Isolated-RT}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "✅ Route Tables Created"

# Add Routes
echo "🔀 Configuring Routes..."

# Public route to Internet Gateway
aws ec2 create-route \
    --route-table-id $PUBLIC_RT_ID \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id $IGW_ID

# Private route to NAT Gateway
aws ec2 create-route \
    --route-table-id $PRIVATE_NAT_RT_ID \
    --destination-cidr-block "0.0.0.0/0" \
    --nat-gateway-id $NAT_GW_ID

# Associate Route Tables with Subnets
echo "🔗 Associating Route Tables..."

# Associate public route table with web subnet
aws ec2 associate-route-table --subnet-id $WEB_SUBNET_ID --route-table-id $PUBLIC_RT_ID

# Associate private NAT route table with app1 and dbcache subnets
aws ec2 associate-route-table --subnet-id $APP1_SUBNET_ID --route-table-id $PRIVATE_NAT_RT_ID
aws ec2 associate-route-table --subnet-id $DBCACHE_SUBNET_ID --route-table-id $PRIVATE_NAT_RT_ID

# Associate isolated route table with app2 and db subnets
aws ec2 associate-route-table --subnet-id $APP2_SUBNET_ID --route-table-id $PRIVATE_ISOLATED_RT_ID
aws ec2 associate-route-table --subnet-id $DB_SUBNET_ID --route-table-id $PRIVATE_ISOLATED_RT_ID

echo "✅ Route Table Associations Complete"

# Output Summary
echo ""
echo "🎉 Production VPC Setup Complete!"
echo "=================================="
echo "VPC ID: $VPC_ID"
echo "Internet Gateway: $IGW_ID"
echo "NAT Gateway: $NAT_GW_ID"
echo ""
echo "Subnets:"
echo "  Web (Public): $WEB_SUBNET_ID"
echo "  App1 (Private-NAT): $APP1_SUBNET_ID"
echo "  App2 (Private-Isolated): $APP2_SUBNET_ID"
echo "  DBCache (Private-NAT): $DBCACHE_SUBNET_ID"
echo "  DB (Private-Isolated): $DB_SUBNET_ID"
echo ""
echo "Route Tables:"
echo "  Public: $PUBLIC_RT_ID"
echo "  Private-NAT: $PRIVATE_NAT_RT_ID"
echo "  Private-Isolated: $PRIVATE_ISOLATED_RT_ID"
echo ""
echo "💡 Next Steps:"
echo "   1. Run setup-development-vpc.sh"
echo "   2. Run setup-security-groups.sh"
echo "   3. Run setup-vpc-peering.sh"
