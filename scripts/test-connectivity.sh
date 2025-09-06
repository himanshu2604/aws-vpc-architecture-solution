#!/bin/bash

# AWS VPC Multi-Tier Architecture - Connectivity Testing
# Tests internet connectivity and VPC peering functionality

set -e  # Exit on any error

echo "🧪 Starting Connectivity Tests..."

# Function to test internet connectivity from an instance
test_internet_connectivity() {
    local instance_name=$1
    local instance_id=$2
    local expected_result=$3
    
    echo "🌐 Testing internet connectivity for $instance_name..."
    
    # Get instance IP
    INSTANCE_IP=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
    
    if [ "$INSTANCE_IP" = "None" ] || [ -z "$INSTANCE_IP" ]; then
        echo "❌ $instance_name: Instance not found or no private IP"
        return 1
    fi
    
    echo "📍 $instance_name Private IP: $INSTANCE_IP"
    
    # Test would require SSH access to instances
    if [ "$expected_result" = "success" ]; then
        echo "✅ $instance_name: Should have internet access"
    else
        echo "🚫 $instance_name: Should NOT have internet access (by design)"
    fi
}

# Function to test VPC peering connectivity
test_peering_connectivity() {
    local source_instance=$1
    local target_instance=$2
    
    echo "🔗 Testing peering connectivity: $source_instance → $target_instance"
    echo "📋 This test requires manual verification with running instances"
}

echo "🔍 Finding EC2 instances..."

# Get Production instances
PROD_WEB_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=web-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

PROD_APP1_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=app1-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

PROD_APP2_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=app2-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

PROD_DBCACHE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=dbcache-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

PROD_DB_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=db-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

# Get Development instances
DEV_WEB_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=dev-web-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

DEV_DB_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=dev-db-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "None")

echo ""
echo "📋 Instance Status:"
echo "Production:"
echo "  Web: $PROD_WEB_ID"
echo "  App1: $PROD_APP1_ID"
echo "  App2: $PROD_APP2_ID"
echo "  DBCache: $PROD_DBCACHE_ID"
echo "  DB: $PROD_DB_ID"
echo "Development:"
echo "  Web: $DEV_WEB_ID"
echo "  DB: $DEV_DB_ID"
echo ""

# Test internet connectivity expectations
echo "🌐 Internet Connectivity Tests:"
echo "================================"

# Production instances
if [ "$PROD_WEB_ID" != "None" ]; then
    test_internet_connectivity "Production Web" $PROD_WEB_ID "success"
else
    echo "⚠️  Production Web instance not found or not running"
fi

if [ "$PROD_APP1_ID" != "None" ]; then
    test_internet_connectivity "Production App1" $PROD_APP1_ID "success"
else
    echo "⚠️  Production App1 instance not found or not running"
fi

if [ "$PROD_APP2_ID" != "None" ]; then
    test_internet_connectivity "Production App2" $PROD_APP2_ID "blocked"
else
    echo "⚠️  Production App2 instance not found or not running"
fi

if [ "$PROD_DBCACHE_ID" != "None" ]; then
    test_internet_connectivity "Production DBCache" $PROD_DBCACHE_ID "success"
else
    echo "⚠️  Production DBCache instance not found or not running"
fi

if [ "$PROD_DB_ID" != "None" ]; then
    test_internet_connectivity "Production DB" $PROD_DB_ID "blocked"
else
    echo "⚠️  Production DB instance not found or not running"
fi

if [ "$DEV_WEB_ID" != "None" ]; then
    test_internet_connectivity "Development Web" $DEV_WEB_ID "success"
else
    echo "⚠️  Development Web instance not found or not running"
fi

if [ "$DEV_DB_ID" != "None" ]; then
    test_internet_connectivity "Development DB" $DEV_DB_ID "blocked"
else
    echo "⚠️  Development DB instance not found or not running"
fi

echo ""
echo "🔗 VPC Peering Tests:"
echo "====================="

# Test VPC peering connectivity
if [ "$PROD_DB_ID" != "None" ] && [ "$DEV_DB_ID" != "None" ]; then
    test_peering_connectivity "Production DB" "Development DB"
    test_peering_connectivity "Development DB" "Production DB"
else
    echo "⚠️  Cannot test peering - DB instances not running in both VPCs"
fi

echo ""
echo "🔍 VPC Peering Connection Status:"
PEERING_ID=$(aws ec2 describe-vpc-peering-connections \
    --filters "Name=tag:Name,Values=Production-Development-Peering" \
    --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
    --output text 2>/dev/null || echo "None")

if [ "$PEERING_ID" != "None" ]; then
    PEERING_STATE=$(aws ec2 describe-vpc-peering-connections \
        --vpc-peering-connection-ids $PEERING_ID \
        --query 'VpcPeeringConnections[0].Status.Code' \
        --output text)
    echo "✅ Peering Connection: $PEERING_ID"
    echo "📊 Status: $PEERING_STATE"
else
    echo "❌ No peering connection found"
fi

echo ""
echo "📊 Manual Testing Instructions:"
echo "==============================="
echo "For detailed connectivity testing, SSH into instances and run:"
echo ""
echo "1. Internet Connectivity Test:"
echo "   ssh -i your-key.pem ec2-user@<instance-ip>"
echo "   curl -s http://checkip.amazonaws.com"
echo ""
echo "2. Cross-VPC Connectivity Test:"
echo "   From Production DB instance:"
echo "   ping <dev-db-private-ip>"
echo ""
echo "   From Development DB instance:"
echo "   ping <prod-db-private-ip>"
echo ""
echo "3. Database Connectivity Test:"
echo "   mysql -h <remote-db-ip> -u username -p"
echo ""
echo "🎉 Connectivity testing script completed!"
echo ""
echo "💡 Expected Results:"
echo "   ✅ Web subnets: Internet access"
echo "   ✅ App1, DBCache: Internet via NAT"
echo "   ❌ App2, DB: No internet (isolated)"
echo "   ✅ Production DB ↔ Development DB: Cross-VPC access"
