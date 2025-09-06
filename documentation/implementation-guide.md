# AWS VPC Multi-Tier Architecture Implementation Guide

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Phase 1: Production VPC Setup](#phase-1-production-vpc-setup)
- [Phase 2: Development VPC Setup](#phase-2-development-vpc-setup)  
- [Phase 3: VPC Peering Configuration](#phase-3-vpc-peering-configuration)
- [Phase 4: Security Configuration](#phase-4-security-configuration)
- [Phase 5: Testing & Validation](#phase-5-testing--validation)

## 🛠️ Prerequisites

### AWS Account Requirements
- Active AWS account with appropriate permissions
- Admin access to VPC, EC2, and IAM services
- AWS CLI configured (optional for automation)

### Technical Prerequisites
- Basic understanding of networking concepts
- Knowledge of CIDR blocks and subnetting
- SSH key pair for EC2 instance access
- Familiarity with AWS Management Console

### Planning Checklist
- [ ] CIDR block planning completed
- [ ] Security group rules defined
- [ ] Instance placement strategy confirmed
- [ ] Cost budget approved
- [ ] Testing plan prepared

---

## 📊 Phase 1: Production VPC Setup

### Step 1.1: Create Production VPC

1. **Navigate to VPC Console**
   - AWS Management Console → Services → VPC
   - Click "Create VPC"

2. **VPC Configuration**
   ```
   🔧 Configuration Settings:
   - Name tag: Production-VPC
   - IPv4 CIDR block: 10.0.0.0/16
   - IPv6 CIDR block: No IPv6 CIDR block
   - Tenancy: Default
   - Tags: Environment=Production, Project=VPC-Case-Study
   ```

3. **Click "Create VPC"**
   - Wait for VPC creation to complete
   - Note the VPC ID for future reference

### Step 1.2: Create Internet Gateway

1. **Create Internet Gateway**
   - VPC Console → Internet Gateways → "Create internet gateway"
   - Name tag: `Production-IGW`
   - Click "Create internet gateway"

2. **Attach to VPC**
   - Select the created IGW → Actions → "Attach to VPC"
   - Select `Production-VPC`
   - Click "Attach internet gateway"

### Step 1.3: Create Production Subnets

#### 🌐 Public Subnet (Web Tier)
```bash
📍 Web Subnet Configuration:
- Name: web
- VPC: Production-VPC
- Availability Zone: us-east-1a
- IPv4 CIDR block: 10.0.1.0/24
- Auto-assign public IPv4: Enable
```

#### 🔒 Private Subnets

**App1 Subnet (Internet-enabled)**
```bash
📍 App1 Subnet Configuration:
- Name: app1
- VPC: Production-VPC
- Availability Zone: us-east-1a
- IPv4 CIDR block: 10.0.2.0/24
- Auto-assign public IPv4: Disable
```

**App2 Subnet (Isolated)**
```bash
📍 App2 Subnet Configuration:
- Name: app2
- VPC: Production-VPC
- Availability Zone: us-east-1b
- IPv4 CIDR block: 10.0.3.0/24
- Auto-assign public IPv4: Disable
```

**DBCache Subnet (Internet-enabled)**
```bash
📍 DBCache Subnet Configuration:
- Name: dbcache
- VPC: Production-VPC
- Availability Zone: us-east-1a
- IPv4 CIDR block: 10.0.4.0/24
- Auto-assign public IPv4: Disable
```

**Database Subnet (Isolated)**
```bash
📍 DB Subnet Configuration:
- Name: db
- VPC: Production-VPC
- Availability Zone: us-east-1b
- IPv4 CIDR block: 10.0.5.0/24
- Auto-assign public IPv4: Disable
```

### Step 1.4: Create NAT Gateway

1. **Create NAT Gateway**
   - VPC Console → NAT Gateways → "Create NAT gateway"
   - Configuration:
     ```
     🔧 NAT Gateway Settings:
     - Name: Production-NAT
     - Subnet: web (public subnet)
     - Connectivity type: Public
     - Elastic IP allocation: Click "Allocate Elastic IP"
     ```

2. **Wait for Creation**
   - NAT Gateway creation takes 5-10 minutes
   - Note the NAT Gateway ID

### Step 1.5: Create Route Tables

#### 🛣️ Public Route Table
1. **Create Route Table**
   - VPC Console → Route Tables → "Create route table"
   - Name: `Production-Public-RT`
   - VPC: `Production-VPC`

2. **Add Internet Route**
   - Select route table → Routes tab → "Edit routes"
   - Add route:
     - Destination: `0.0.0.0/0`
     - Target: Internet Gateway (`Production-IGW`)
   - Save changes

3. **Associate Public Subnet**
   - Subnet associations tab → "Edit subnet associations"
   - Select `web` subnet → Save associations

#### 🛣️ Private Route Table (NAT-enabled)
1. **Create Private Route Table**
   - Name: `Production-Private-NAT-RT`
   - VPC: `Production-VPC`

2. **Add NAT Gateway Route**
   - Routes tab → "Edit routes"
   - Add route:
     - Destination: `0.0.0.0/0`
     - Target: NAT Gateway (`Production-NAT`)
   - Save changes

3. **Associate Subnets**
   - Associate `app1` and `dbcache` subnets

#### 🛣️ Private Route Table (Isolated)
1. **Create Isolated Route Table**
   - Name: `Production-Private-Isolated-RT`
   - VPC: `Production-VPC`
   - Keep only local route (default)

2. **Associate Isolated Subnets**
   - Associate `app2` and `db` subnets

---

## 🏢 Phase 2: Development VPC Setup

### Step 2.1: Create Development VPC

1. **VPC Configuration**
   ```
   🔧 Development VPC Settings:
   - Name tag: Development-VPC
   - IPv4 CIDR block: 10.1.0.0/16
   - IPv6 CIDR block: No IPv6 CIDR block
   - Tenancy: Default
   - Tags: Environment=Development, Project=VPC-Case-Study
   ```

### Step 2.2: Create Development Internet Gateway

1. **Create and Attach IGW**
   - Name: `Development-IGW`
   - Attach to `Development-VPC`

### Step 2.3: Create Development Subnets

#### 🌐 Development Web Subnet (Public)
```bash
📍 Dev-Web Subnet Configuration:
- Name: dev-web
- VPC: Development-VPC
- Availability Zone: us-east-1a
- IPv4 CIDR block: 10.1.1.0/24
- Auto-assign public IPv4: Enable
```

#### 🔒 Development Database Subnet (Private)
```bash
📍 Dev-DB Subnet Configuration:
- Name: dev-db
- VPC: Development-VPC
- Availability Zone: us-east-1b
- IPv4 CIDR block: 10.1.2.0/24
- Auto-assign public IPv4: Disable
```

### Step 2.4: Create Development Route Tables

#### 🛣️ Development Public Route Table
1. **Create and Configure**
   - Name: `Development-Public-RT`
   - Add internet gateway route (`0.0.0.0/0` → `Development-IGW`)
   - Associate `dev-web` subnet

#### 🛣️ Development Private Route Table
1. **Create and Configure**
   - Name: `Development-Private-RT`
   - Keep only local route (no internet access)
   - Associate `dev-db` subnet

---

## 🔗 Phase 3: VPC Peering Configuration

### Step 3.1: Create VPC Peering Connection

1. **Navigate to Peering Connections**
   - VPC Console → Peering Connections → "Create Peering Connection"

2. **Peering Connection Settings**
   ```
   🔗 Peering Configuration:
   - Name tag: Production-Development-Peering
   - VPC (Requester): Production-VPC
   - Account: My account
   - Region: This region
   - VPC (Accepter): Development-VPC
   ```

3. **Create and Accept**
   - Click "Create Peering Connection"
   - Select the connection → Actions → "Accept Request"

### Step 3.2: Update Route Tables for Peering

#### 🛣️ Production DB Route Table Update
1. **Add Peering Route**
   - Select `Production-Private-Isolated-RT`
   - Routes tab → "Edit routes"
   - Add route:
     - Destination: `10.1.0.0/16` (Development VPC CIDR)
     - Target: Peering Connection (`Production-Development-Peering`)

#### 🛣️ Development DB Route Table Update
1. **Add Peering Route**
   - Select `Development-Private-RT`
   - Routes tab → "Edit routes"
   - Add route:
     - Destination: `10.0.0.0/16` (Production VPC CIDR)
     - Target: Peering Connection (`Production-Development-Peering`)

---

## 🔒 Phase 4: Security Configuration

### Step 4.1: Create Production Security Groups

#### 🛡️ Web Tier Security Group
```bash
📋 Production-Web-SG Configuration:
Name: Production-Web-SG
VPC: Production-VPC

Inbound Rules:
- HTTP (80): 0.0.0.0/0 "Allow web traffic"
- HTTPS (443): 0.0.0.0/0 "Allow secure web traffic"
- SSH (22): [Your IP]/32 "Admin access only"

Outbound Rules:
- All traffic: 0.0.0.0/0 "Default outbound"
```

#### 🛡️ Application Tier Security Group
```bash
📋 Production-App-SG Configuration:
Name: Production-App-SG
VPC: Production-VPC

Inbound Rules:
- Custom TCP (8080): Production-Web-SG "App traffic from web tier"
- SSH (22): Production-Web-SG "SSH via bastion"

Outbound Rules:
- All traffic: 0.0.0.0/0 "Default outbound"
```

#### 🛡️ Cache Tier Security Group
```bash
📋 Production-Cache-SG Configuration:
Name: Production-Cache-SG
VPC: Production-VPC

Inbound Rules:
- Redis (6379): Production-App-SG "Cache access from app tier"
- SSH (22): Production-Web-SG "SSH via bastion"

Outbound Rules:
- All traffic: 0.0.0.0/0 "Default outbound"
```

#### 🛡️ Database Tier Security Group
```bash
📋 Production-DB-SG Configuration:
Name: Production-DB-SG
VPC: Production-VPC

Inbound Rules:
- MySQL (3306): Production-App-SG "DB access from app tier"
- MySQL (3306): Production-Cache-SG "DB access from cache tier"
- MySQL (3306): 10.1.2.0/24 "Cross-VPC DB access"
- SSH (22): Production-Web-SG "SSH via bastion"

Outbound Rules:
- All traffic: 0.0.0.0/0 "Default outbound"
```

### Step 4.2: Create Development Security Groups

#### 🛡️ Development Web Security Group
```bash
📋 Dev-Web-SG Configuration:
Name: Dev-Web-SG
VPC: Development-VPC

Inbound Rules:
- HTTP (80): 0.0.0.0/0 "Allow web traffic"
- HTTPS (443): 0.0.0.0/0 "Allow secure web traffic"
- SSH (22): [Your IP]/32 "Admin access only"
```

#### 🛡️ Development Database Security Group
```bash
📋 Dev-DB-SG Configuration:
Name: Dev-DB-SG
VPC: Development-VPC

Inbound Rules:
- MySQL (3306): Dev-Web-SG "DB access from web tier"
- MySQL (3306): 10.0.5.0/24 "Cross-VPC DB access"
- SSH (22): Dev-Web-SG "SSH via bastion"
```

### Step 4.3: Launch EC2 Instances

#### 🖥️ Production Instances

**Web Instance**
```bash
Instance Configuration:
- Name: web-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Production-VPC
- Subnet: web
- Auto-assign public IP: Enable
- Security group: Production-Web-SG
- Key pair: [Your key pair]
```

**App1 Instance**
```bash
Instance Configuration:
- Name: app1-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Production-VPC
- Subnet: app1
- Auto-assign public IP: Disable
- Security group: Production-App-SG
- Key pair: [Your key pair]
```

**App2 Instance**
```bash
Instance Configuration:
- Name: app2-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Production-VPC
- Subnet: app2
- Auto-assign public IP: Disable
- Security group: Production-App-SG
- Key pair: [Your key pair]
```

**DBCache Instance**
```bash
Instance Configuration:
- Name: dbcache-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Production-VPC
- Subnet: dbcache
- Auto-assign public IP: Disable
- Security group: Production-Cache-SG
- Key pair: [Your key pair]
```

**Database Instance**
```bash
Instance Configuration:
- Name: db-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Production-VPC
- Subnet: db
- Auto-assign public IP: Disable
- Security group: Production-DB-SG
- Key pair: [Your key pair]
```

#### 🖥️ Development Instances

**Development Web Instance**
```bash
Instance Configuration:
- Name: dev-web-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Development-VPC
- Subnet: dev-web
- Auto-assign public IP: Enable
- Security group: Dev-Web-SG
- Key pair: [Your key pair]
```

**Development Database Instance**
```bash
Instance Configuration:
- Name: dev-db-instance
- AMI: Amazon Linux 2
- Instance type: t3.micro
- VPC: Development-VPC
- Subnet: dev-db
- Auto-assign public IP: Disable
- Security group: Dev-DB-SG
- Key pair: [Your key pair]
```

---

## 🧪 Phase 5: Testing & Validation

### Step 5.1: Internet Connectivity Testing

#### ✅ Test Internet Access
```bash
# Connect to web instance (should work)
ssh -i your-key.pem ec2-user@[web-instance-public-ip]
curl -s http://checkip.amazonaws.com

# Connect to app1 instance via web instance (should work via NAT)
ssh -i your-key.pem ec2-user@[app1-instance-private-ip]
curl -s http://checkip.amazonaws.com

# Connect to app2 instance via web instance (should fail - no internet)
ssh -i your-key.pem ec2-user@[app2-instance-private-ip]
curl -s --connect-timeout 5 http://checkip.amazonaws.com

# Test dbcache instance (should work via NAT)
ssh -i your-key.pem ec2-user@[dbcache-instance-private-ip]
curl -s http://checkip.amazonaws.com

# Test db instance (should fail - no internet)
ssh -i your-key.pem ec2-user@[db-instance-private-ip]
curl -s --connect-timeout 5 http://checkip.amazonaws.com
```

### Step 5.2: VPC Peering Validation

#### ✅ Test Cross-VPC Connectivity
```bash
# From Production DB instance
ssh -i your-key.pem ec2-user@[production-db-private-ip]
ping [development-db-private-ip]

# From Development DB instance  
ssh -i your-key.pem ec2-user@[development-db-private-ip]
ping [production-db-private-ip]

# Test database connectivity (if MySQL installed)
mysql -h [remote-db-ip] -u testuser -p testdb
```

### Step 5.3: Security Group Validation

#### 🔍 Test Security Rules
```bash
# Test unauthorized access (should fail)
telnet [db-instance-ip] 3306  # From unauthorized source

# Test authorized access (should work)
telnet [db-instance-ip] 3306  # From app instance

# Port scanning test
nmap -p 80,443,22,3306 [instance-ip]
```

### Step 5.4: Route Table Verification

#### 📋 Validate Routing
```bash
# Check route tables in AWS Console
# Verify each subnet is associated with correct route table
# Confirm routes are pointing to correct targets

# Test trace route
traceroute 8.8.8.8  # From different instances
```

---

## ✅ Implementation Checklist

### Production VPC
- [ ] VPC created with correct CIDR (10.0.0.0/16)
- [ ] Internet Gateway created and attached
- [ ] 5 subnets created with correct CIDRs
- [ ] NAT Gateway created in public subnet
- [ ] Route tables configured correctly
- [ ] EC2 instances launched in all subnets
- [ ] Security groups configured
- [ ] Internet connectivity verified

### Development VPC
- [ ] VPC created with correct CIDR (10.1.0.0/16)
- [ ] Internet Gateway created and attached
- [ ] 2 subnets created with correct CIDRs
- [ ] Route tables configured correctly
- [ ] EC2 instances launched in both subnets
- [ ] Security groups configured
- [ ] Internet connectivity verified

### VPC Peering
- [ ] Peering connection created and accepted
- [ ] Route tables updated for cross-VPC communication
- [ ] Security groups allow cross-VPC traffic
- [ ] Cross-VPC connectivity tested and verified

### Security & Testing
- [ ] All security groups configured correctly
- [ ] Internet access working as designed
- [ ] VPC peering connectivity verified
- [ ] Security isolation confirmed
- [ ] Cost optimization implemented

---

## 📞 Support & Troubleshooting

### Common Issues
- **Instance can't access internet**: Check route table associations and NAT Gateway
- **Cross-VPC communication fails**: Verify peering connection and route tables
- **Security group blocked**: Check inbound/outbound rules and source/destination
- **SSH access issues**: Verify key pair and security group SSH rules

### Monitoring & Logging
- Enable VPC Flow Logs for network monitoring
- Set up CloudWatch alarms for key metrics
- Monitor NAT Gateway data transfer costs
- Regular security group audits

---

## 🎯 Next Steps

1. **Install Applications**: Deploy web servers, databases, and applications
2. **Configure Monitoring**: Set up comprehensive monitoring and alerting
3. **Implement Auto Scaling**: Configure auto scaling groups for high availability
4. **Setup Load Balancing**: Add Application Load Balancers for production
5. **Enhance Security**: Implement AWS WAF, GuardDuty, and other security services
6. **Backup Strategy**: Configure automated backup solutions
7. **Disaster Recovery**: Implement cross-region disaster recovery

---

**Implementation Complete!** 🎉

Your AWS VPC Multi-Tier Architecture with VPC Peering is now fully deployed and tested. The infrastructure provides a secure, scalable, and cost-effective foundation for your applications.
