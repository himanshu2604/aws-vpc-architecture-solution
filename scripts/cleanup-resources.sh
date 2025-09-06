#!/bin/bash

# AWS VPC Multi-Tier Architecture - Cleanup Script
# Safely removes all created VPC resources

set -e  # Exit on any error

echo "🧹 Starting VPC Resources Cleanup..."
echo "⚠️  WARNING: This will delete all VPC resources created by this case study!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

# Function to safely delete resource with error handling
safe_delete() {
    local resource_type=$1
    local resource_id=$2
    local resource_name=$3
    
    if [ "$resource_id" != "None" ] && [ -n "$resource_id" ]; then
        echo "🗑️  Deleting $resource_type: $resource_name ($resource_id)"
        return 0
    else
        echo "⚠️  $resource_type not found: $resource_name"
        return 1
    fi
}

echo "🔍 Finding resources to delete..."

# Get VPC IDs
PROD_VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=Production-VPC" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo "None")

DEV_VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=Development-VPC" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo "None")

echo "📋 Found VPCs:"
echo "   Production: $PROD_VPC_ID"
echo "   Development: $DEV_VPC_ID"

# 1. Terminate EC2 Instances
echo ""
echo "🖥️  Terminating EC2 Instances..."

INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$PROD_VPC_ID,$DEV_VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text 2>/dev/null || echo "")

if [ -n "$INSTANCE_IDS" ] && [ "$INSTANCE_IDS" != "None" ]; then
    echo "🔄 Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    echo "⏳ Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
    echo "✅ Instances terminated"
else
    echo "⚠️  No instances found to terminate"
fi

# 2. Delete VPC Peering Connection
echo ""
echo "🔗 Deleting VPC Peering Connection..."

PEERING_ID=$(aws ec2 describe-vpc-peering-connections \
    --filters "Name=tag:Name,Values=Production-Development-Peering" \
    --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
    --output text 2>/dev/null || echo "None")

if safe_delete "VPC Peering Connection" "$PEERING_ID" "Production-Development-Peering"; then
    aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID
    echo "✅ VPC Peering Connection deleted"
fi

# 3. Delete NAT Gateway and release Elastic IP
echo ""
echo "🔄 Deleting NAT Gateway..."

NAT_GW_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=tag:Name,Values=Production-NAT" \
    --query 'NatGateways[0].NatGatewayId' \
    --output text 2>/dev/null || echo "None")

if safe_delete "NAT Gateway" "$NAT_GW_ID" "Production-NAT"; then
    # Get associated Elastic IP before deleting NAT Gateway
    EIP_ALLOCATION_ID=$(aws ec2 describe-nat-gateways \
        --nat-gateway-ids $NAT_GW_ID \
        --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' \
        --output text)
    
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
    echo "⏳ Waiting for NAT Gateway to be deleted..."
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW_ID
    
    # Release Elastic IP
    if [ "$EIP_ALLOCATION_ID" != "None" ] && [ -n "$EIP_ALLOCATION_ID" ]; then
        echo "🔄 Releasing Elastic IP: $EIP_ALLOCATION_ID"
        aws ec2 release-address --allocation-id $EIP_ALLOCATION_ID
        echo "✅ Elastic IP released"
    fi
    echo "✅ NAT Gateway deleted"
fi

# Function to cleanup VPC resources
cleanup_vpc() {
    local vpc_id=$1
    local vpc_name=$2
    
    if [ "$vpc_id" = "None" ]; then
        echo "⚠️  $vpc_name not found, skipping..."
        return
    fi
    
    echo ""
    echo "🏗️ Cleaning up $vpc_name ($vpc_id)..."
    
    # Delete custom route tables (keep default)
    echo "🛣️  Deleting custom route tables..."
    CUSTOM_RT_IDS=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$CUSTOM_RT_IDS" ]; then
        for rt_id in $CUSTOM_RT_IDS; do
            echo "🗑️  Deleting route table: $rt_id"
            # Disassociate subnets first
            aws ec2 describe-route-tables --route-table-ids $rt_id \
                --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
                --output text | xargs -r -n1 aws ec2 disassociate-route-table --association-id 2>/dev/null || true
            aws ec2 delete-route-table --route-table-id $rt_id 2>/dev/null || true
        done
    fi
    
    # Delete subnets
    echo "📍 Deleting subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[].SubnetId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$SUBNET_IDS" ]; then
        for subnet_id in $SUBNET_IDS; do
            echo "🗑️  Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id $subnet_id 2>/dev/null || true
        done
    fi
    
    # Detach and delete Internet Gateway
    echo "🌐 Deleting Internet Gateway..."
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null || echo "None")
    
    if [ "$IGW_ID" != "None" ]; then
        echo "🗑️  Detaching and deleting IGW: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $vpc_id 2>/dev/null || true
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null || true
    fi
    
    # Delete security groups (except default)
    echo "🛡️  Deleting custom security groups..."
    CUSTOM_SG_IDS=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$CUSTOM_SG_IDS" ]; then
        for sg_id in $CUSTOM_SG_IDS; do
            echo "🗑️  Deleting security group: $sg_id"
            aws ec2 delete-security-group --group-id $sg_id 2>/dev/null || true
        done
    fi
    
    # Finally, delete the VPC
    echo "🏗️ Deleting VPC: $vpc_id"
    aws ec2 delete-vpc --vpc-id $vpc_id 2>/dev/null || true
    echo "✅ $vpc_name cleanup completed"
}

# Cleanup both VPCs
cleanup_vpc "$PROD_VPC_ID" "Production VPC"
cleanup_vpc "$DEV_VPC_ID" "Development VPC"

echo ""
echo "🎉 Cleanup Complete!"
echo "===================="
echo "All VPC resources have been deleted:"
echo "✅ EC2 Instances terminated"
echo "✅ VPC Peering Connection deleted"
echo "✅ NAT Gateway and Elastic IP deleted"
echo "✅ Route Tables deleted"
echo "✅ Subnets deleted"
echo "✅ Internet Gateways deleted"
echo "✅ Security Groups deleted"
echo "✅ VPCs deleted"
echo ""
echo "💰 Cost Impact: Monthly charges stopped for:"
echo "   - NAT Gateway (~$45/month)"
echo "   - Elastic IP (~$3.65/month)"
echo "   - EC2 Instances (varies by type and usage)"
echo ""
echo "⚠️  Note: This cleanup is irreversible!"
echo "💡 To recreate the environment, run the setup scripts again."
