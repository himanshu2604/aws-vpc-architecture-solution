#!/bin/bash

# AWS VPC Multi-Tier Architecture - Development VPC Setup
# Creates Development VPC with 2-tier architecture (Web, DB)

set -e  # Exit on any error

# Configuration Variables
VPC_NAME="Development-VPC"
VPC_CIDR="10.1.0.0/16"
REGION="us-east-1"
AZ_A="us-east-1a"
AZ_B="us-east-1b"

echo "🏢 Setting up Development VPC..."

# Create VPC
echo "📊 Creating Development VPC..."
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
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Development-IGW}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "✅ Internet Gateway Created and Attached: $IGW_ID"

# Create Subnets
echo "📍 Creating Subnets..."

# Dev Web Subnet (Public)
DEV_WEB_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.1.1.0/24" \
    --availability-zone $AZ_A \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=dev-web}]" \
    --query 'Subnet.SubnetId' \
    --output text)

# Dev DB Subnet (Private)
DEV_DB_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "10.1.2.0/24" \
    --availability-zone $AZ_B \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=dev-db}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "✅ Subnets Created:"
echo "   Dev-Web: $DEV_WEB_SUBNET_ID"
echo "   Dev-DB: $DEV_DB_SUBNET_ID"

# Enable auto-assign public IP for dev web subnet
aws ec2 modify-subnet-attribute --subnet-id $DEV_WEB_SUBNET_ID --map-public-ip-on-launch

# Create Route Tables
echo "🛣️ Creating Route Tables..."

# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Development-Public-RT}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Development-Private-RT}]" \
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

# Associate Route Tables with Subnets
echo "🔗 Associating Route Tables..."

# Associate public route table with dev web subnet
aws ec2 associate-route-table --subnet-id $DEV_WEB_SUBNET_ID --route-table-id $PUBLIC_RT_ID

# Associate private route table with dev db subnet
aws ec2 associate-route-table --subnet-id $DEV_DB_SUBNET_ID --route-table-id $PRIVATE_RT_ID

echo "✅ Route Table Associations Complete"

# Output Summary
echo ""
echo "🎉 Development VPC Setup Complete!"
echo "==================================="
echo "VPC ID: $VPC_ID"
echo "Internet Gateway: $IGW_ID"
echo ""
echo "Subnets:"
echo "  Dev-Web (Public): $DEV_WEB_SUBNET_ID"
echo "  Dev-DB (Private): $DEV_DB_SUBNET_ID"
echo ""
echo "Route Tables:"
echo "  Public: $PUBLIC_RT_ID"
echo "  Private: $PRIVATE_RT_ID"
echo ""
echo "💡 Next Steps:"
echo "   1. Run setup-security-groups.sh"
echo "   2. Run setup-vpc-peering.sh"
echo "   3. Run deploy-ec2-instances.sh"
