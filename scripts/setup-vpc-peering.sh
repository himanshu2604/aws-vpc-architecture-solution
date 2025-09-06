#!/bin/bash

# AWS VPC Multi-Tier Architecture - VPC Peering Setup
# Creates peering connection between Production and Development VPCs

set -e  # Exit on any error

echo "🔗 Setting up VPC Peering..."

# Get VPC IDs by name
echo "📋 Finding VPC IDs..."
PROD_VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=Production-VPC" \
    --query 'Vpcs[0].VpcId' \
    --output text)

DEV_VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=Development-VPC" \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "✅ Found VPCs:"
echo "   Production VPC: $PROD_VPC_ID"
echo "   Development VPC: $DEV_VPC_ID"

# Create VPC Peering Connection
echo "🔗 Creating VPC Peering Connection..."
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id $PROD_VPC_ID \
    --peer-vpc-id $DEV_VPC_ID \
    --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=Production-Development-Peering}]" \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
    --output text)

echo "✅ VPC Peering Connection Created: $PEERING_ID"

# Accept VPC Peering Connection
echo "✅ Accepting VPC Peering Connection..."
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID

# Wait for peering connection to be active
echo "⏳ Waiting for peering connection to be active..."
aws ec2 wait vpc-peering-connection-exists --vpc-peering-connection-ids $PEERING_ID

# Get Route Table IDs
echo "🛣️ Finding Route Table IDs..."

# Production VPC Route Tables
PROD_ISOLATED_RT_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$PROD_VPC_ID" "Name=tag:Name,Values=Production-Private-Isolated-RT" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

# Development VPC Route Tables
DEV_PRIVATE_RT_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$DEV_VPC_ID" "Name=tag:Name,Values=Development-Private-RT" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

echo "✅ Found Route Tables:"
echo "   Production Isolated RT: $PROD_ISOLATED_RT_ID"
echo "   Development Private RT: $DEV_PRIVATE_RT_ID"

# Add peering routes
echo "🔀 Adding peering routes..."

# Add route from Production isolated subnets to Development VPC
aws ec2 create-route \
    --route-table-id $PROD_ISOLATED_RT_ID \
    --destination-cidr-block "10.1.0.0/16" \
    --vpc-peering-connection-id $PEERING_ID

# Add route from Development private subnet to Production VPC
aws ec2 create-route \
    --route-table-id $DEV_PRIVATE_RT_ID \
    --destination-cidr-block "10.0.0.0/16" \
    --vpc-peering-connection-id $PEERING_ID

echo "✅ Peering routes added successfully"

# Test connectivity (optional - requires instances to be running)
echo ""
echo "🔍 Testing peering connection..."
echo "Note: This test requires EC2 instances to be running in both VPCs"

# Output Summary
echo ""
echo "🎉 VPC Peering Setup Complete!"
echo "=============================="
echo "Peering Connection ID: $PEERING_ID"
echo "Production VPC: $PROD_VPC_ID"
echo "Development VPC: $DEV_VPC_ID"
echo ""
echo "📋 Peering Routes Added:"
echo "  Production DB subnet → Development VPC (10.1.0.0/16)"
echo "  Development DB subnet → Production VPC (10.0.0.0/16)"
echo ""
echo "💡 Next Steps:"
echo "   1. Update security groups to allow cross-VPC traffic"
echo "   2. Test connectivity between database subnets"
echo "   3. Deploy EC2 instances for testing"
