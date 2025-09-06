# 🏗️ AWS VPC Multi-Tier Architecture & Peering Solution

[![AWS](https://img.shields.io/badge/AWS-VPC%20Architecture-orange)](https://aws.amazon.com/)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Multi%20Tier-blue)](https://github.com/[your-username]/aws-vpc-architecture-solution)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Study](https://img.shields.io/badge/Academic-Case%20Study-red)](https://github.com/[your-username]/aws-vpc-architecture-solution)

## 📋 Project Overview

**XYZ Corporation VPC Architecture & Network Isolation Solution** - A comprehensive AWS networking implementation demonstrating multi-tier architecture design, VPC peering, and enterprise-grade security for production and development environments.

### 🎯 Key Achievements
- ✅ **4-Tier Production Architecture** - Web, App, Cache, and Database layers
- ✅ **2-Tier Development Architecture** - Simplified web and database setup
- ✅ **Secure Network Isolation** - Private subnets with controlled internet access
- ✅ **VPC Peering Integration** - Cross-environment database connectivity
- ✅ **Enterprise Security** - Multi-layered security groups and NACLs
- ✅ **Cost-Effective Design** - Optimized NAT Gateway usage

## 🏗️ Problem Statement

**Challenge**: XYZ Corporation required separate, secure network environments for production and development teams with specific connectivity and security requirements.

**Solution Requirements**:

### Production Network
1. **4-Tier Architecture**: Web, Application (App1/App2), Cache, and Database layers
2. **5 Subnets**: 1 public (web), 4 private (app1, app2, dbcache, db)
3. **Controlled Internet Access**: Only web, app1, and dbcache subnets can access internet
4. **Security**: Comprehensive security groups and NACLs

### Development Network
1. **2-Tier Architecture**: Web and Database layers
2. **Limited Internet Access**: Only web subnet can send internet requests
3. **Cross-Environment Access**: Database connectivity to production network

### Integration Requirements
1. **VPC Peering**: Connection between production and development networks
2. **Database Communication**: Direct connectivity between DB subnets

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production VPC (10.0.0.0/16)                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Web Subnet  │  │ App1 Subnet │  │ App2 Subnet │             │
│  │ (Public)    │  │ (Private)   │  │ (Private)   │             │
│  │ 10.0.1.0/24 │  │ 10.0.2.0/24 │  │ 10.0.3.0/24 │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│         │                 │                 │                  │
│         │        ┌─────────────┐  ┌─────────────┐              │
│         │        │Cache Subnet │  │ DB Subnet   │              │
│         │        │ (Private)   │  │ (Private)   │              │
│         │        │ 10.0.4.0/24 │  │ 10.0.5.0/24 │              │
│         │        └─────────────┘  └─────────────┘              │
│         │                 │                 │                  │
│  ┌─────────────┐  ┌─────────────┐         │                  │
│  │     IGW     │  │ NAT Gateway │         │                  │
│  └─────────────┘  └─────────────┘         │                  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                              ┌─────────────┐
                              │VPC Peering  │
                              │ Connection  │
                              └─────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────┐
│                  Development VPC (10.1.0.0/16)                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                    ┌─────────────┐             │
│  │Dev Web Sub. │                    │Dev DB Sub.  │             │
│  │ (Public)    │                    │ (Private)   │             │
│  │ 10.1.1.0/24 │                    │ 10.1.2.0/24 │             │
│  └─────────────┘                    └─────────────┘             │
│         │                                   │                   │
│  ┌─────────────┐                           │                   │
│  │     IGW     │                           │                   │
│  └─────────────┘                           │                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Technologies & Services Used

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **VPC** | Network isolation | Production: 10.0.0.0/16, Development: 10.1.0.0/16 |
| **EC2** | Compute resources | Named instances per subnet |
| **Internet Gateway** | Internet connectivity | Attached to both VPCs |
| **NAT Gateway** | Private subnet internet | Production VPC only |
| **Route Tables** | Traffic routing | Separate tables for public/private |
| **Security Groups** | Instance-level firewall | Tier-based security rules |
| **NACLs** | Subnet-level security | Additional network protection |
| **VPC Peering** | Cross-VPC communication | Database subnet connectivity |

## 📂 Repository Structure

```
aws-vpc-architecture-solution/
├── 📋 documentation/
│   ├── AWS-VPC-Case-Study-Solution.md    # Complete implementation guide
│   ├── architecture-overview.md          # Architecture deep dive
│   ├── security-analysis.md             # Security implementation details
│   └── network-diagram.png              # Visual architecture diagram
├── 🔧 configurations/
│   ├── production-vpc/
│   │   ├── vpc-config.json              # Production VPC configuration
│   │   ├── subnets-config.json          # 5 subnets configuration
│   │   ├── route-tables.json            # Routing configuration
│   │   ├── security-groups.json         # Production security groups
│   │   └── nacls-config.json            # Network ACLs
│   ├── development-vpc/
│   │   ├── vpc-config.json              # Development VPC configuration
│   │   ├── subnets-config.json          # 2 subnets configuration
│   │   ├── route-tables.json            # Routing configuration
│   │   └── security-groups.json         # Development security groups
│   ├── peering/
│   │   ├── peering-connection.json      # VPC peering configuration
│   │   └── cross-vpc-routes.json        # Cross-VPC routing rules
│   └── ec2-instances/
│       ├── launch-templates.json        # Instance launch templates
│       └── instance-configs.json        # Per-subnet instance configs
├── 🚀 deployment-scripts/
│   ├── gui-implementation/
│   │   └── step-by-step-guide.md        # Detailed GUI instructions
│   ├── automated-setup/
│   │   ├── create-production-vpc.sh     # Production VPC automation
│   │   ├── create-development-vpc.sh    # Development VPC automation
│   │   ├── setup-peering.sh             # VPC peering automation
│   │   └── launch-instances.sh          # EC2 instance deployment
│   └── validation/
│       ├── test-connectivity.sh         # Network connectivity tests
│       ├── security-validation.py       # Security rules testing
│       └── internet-access-check.sh     # Internet access validation
├── 📸 screenshots/
│   ├── vpc-overview/
│   ├── subnet-configurations/
│   ├── security-groups/
│   ├── peering-connection/
│   ├── instance-deployment/
│   └── connectivity-tests/
├── 🔒 security/
│   ├── security-group-rules.md          # Detailed SG rules explanation
│   ├── nacl-configurations.md           # NACL rules and best practices
│   ├── network-segmentation.md          # Network isolation strategy
│   └── compliance-checklist.md          # Security compliance validation
├── 🧪 testing/
│   ├── connectivity-tests/
│   │   ├── internet-access-results.md   # Internet connectivity validation
│   │   ├── cross-vpc-communication.md   # VPC peering test results
│   │   └── security-boundary-tests.md   # Security isolation testing
│   ├── performance-analysis/
│   │   ├── network-latency-tests.json   # Cross-AZ latency measurements
│   │   └── throughput-analysis.md       # Network performance metrics
│   └── disaster-recovery/
│       ├── failover-testing.md          # Multi-AZ failover tests
│       └── backup-strategies.md         # Data protection approaches
└── 📚 troubleshooting/
    ├── common-issues.md                 # Frequently encountered problems
    ├── debugging-guide.md               # Network troubleshooting steps
    └── best-practices.md                # AWS VPC best practices
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate IAM permissions
- Basic understanding of networking concepts
- SSH key pair for EC2 instance access

### GUI Implementation Steps

#### 1. **Production VPC Setup**
```bash
# Navigate to AWS Console → VPC
# Create Production VPC (10.0.0.0/16)
# Create Internet Gateway and NAT Gateway
# Configure 5 subnets: web (public), app1, app2, dbcache, db (private)
# Setup route tables with proper routing
```

#### 2. **Development VPC Setup**
```bash
# Create Development VPC (10.1.0.0/16)
# Create Internet Gateway
# Configure 2 subnets: dev-web (public), dev-db (private)
# Setup route tables
```

#### 3. **Security Configuration**
```bash
# Create tier-based security groups
# Configure NACLs for additional security
# Implement least-privilege access principles
```

#### 4. **VPC Peering Setup**
```bash
# Create peering connection between VPCs
# Update route tables for cross-VPC communication
# Configure security groups for database connectivity
```

#### 5. **Instance Deployment**
```bash
# Launch EC2 instances in each subnet
# Name instances according to subnet names
# Configure security group associations
```

### Automated Deployment
```bash
# Clone the repository
git clone https://github.com/[your-username]/aws-vpc-architecture-solution.git
cd aws-vpc-architecture-solution

# Run automated setup
chmod +x deployment-scripts/automated-setup/*.sh
./deployment-scripts/automated-setup/create-production-vpc.sh
./deployment-scripts/automated-setup/create-development-vpc.sh
./deployment-scripts/automated-setup/setup-peering.sh
./deployment-scripts/automated-setup/launch-instances.sh
```

## 📊 Implementation Results

### Network Architecture
| Component | Production | Development |
|-----------|------------|-------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Subnets** | 5 (1 public, 4 private) | 2 (1 public, 1 private) |
| **Internet Access** | Web, App1, DBCache | Web only |
| **Cross-VPC Access** | DB subnet | DB subnet |

### Security Implementation
- **Production Security Groups**: 4 tier-based groups (Web, App, Cache, DB)
- **Development Security Groups**: 2 groups (Web, DB)
- **Network ACLs**: Custom rules for additional subnet-level security
- **Internet Access Control**: NAT Gateway for private subnet internet access

### Connectivity Matrix
| Source | Destination | Access | Method |
|--------|-------------|--------|---------|
| Production Web | Internet | ✅ | Internet Gateway |
| Production App1 | Internet | ✅ | NAT Gateway |
| Production DBCache | Internet | ✅ | NAT Gateway |
| Production App2 | Internet | ❌ | No route |
| Production DB | Internet | ❌ | No route |
| Development Web | Internet | ✅ | Internet Gateway |
| Development DB | Internet | ❌ | No route |
| Production DB | Development DB | ✅ | VPC Peering |
| Development DB | Production DB | ✅ | VPC Peering |

## 🔍 Network Segmentation Details

### Production Network (4-Tier)
1. **Web Tier** (10.0.1.0/24)
   - Public subnet with Internet Gateway access
   - Hosts web servers and load balancers
   - Security: HTTP/HTTPS from internet, SSH from admin

2. **Application Tier - App1** (10.0.2.0/24)
   - Private subnet with NAT Gateway internet access
   - Hosts application servers requiring internet connectivity
   - Security: Communication from web tier, outbound internet

3. **Application Tier - App2** (10.0.3.0/24)
   - Private subnet with no internet access
   - Hosts internal application components
   - Security: Communication from web and app1 tiers only

4. **Cache Tier** (10.0.4.0/24)
   - Private subnet with NAT Gateway internet access
   - Hosts caching services (Redis, Memcached)
   - Security: Communication from app tiers, outbound internet

5. **Database Tier** (10.0.5.0/24)
   - Private subnet with no internet access
   - Hosts database servers
   - Security: Communication from app and cache tiers, VPC peering

### Development Network (2-Tier)
1. **Web Tier** (10.1.1.0/24)
   - Public subnet for development web servers
   - Internet access for development activities

2. **Database Tier** (10.1.2.0/24)
   - Private subnet for development databases
   - VPC peering access to production database subnet

## 🧪 Testing & Validation

### Internet Connectivity Tests
```bash
# Test internet access from each instance
ssh -i key.pem ec2-user@web-instance "curl -s http://checkip.amazonaws.com"
ssh -i key.pem ec2-user@app1-instance "curl -s http://checkip.amazonaws.com"
ssh -i key.pem ec2-user@dbcache-instance "curl -s http://checkip.amazonaws.com"

# Verify no internet access for isolated subnets
ssh -i key.pem ec2-user@app2-instance "curl -s --connect-timeout 5 http://checkip.amazonaws.com"
ssh -i key.pem ec2-user@db-instance "curl -s --connect-timeout 5 http://checkip.amazonaws.com"
```

### VPC Peering Validation
```bash
# Test cross-VPC database connectivity
# From Production DB instance
ping 10.1.2.10  # Development DB instance IP

# From Development DB instance  
ping 10.0.5.10  # Production DB instance IP

# Test database connection
mysql -h 10.1.2.10 -u dbuser -p testdb
```

### Security Validation
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-names "Production-Web-SG"
aws ec2 describe-security-groups --group-names "Production-DB-SG"

# Test port accessibility
nmap -p 80,443,22 production-web-instance-ip
nmap -p 3306 production-db-instance-ip
```

## 🔒 Security Best Practices Implemented

### Network Security
- **Principle of Least Privilege**: Minimal required access only
- **Defense in Depth**: Multiple security layers (SGs + NACLs)
- **Network Segmentation**: Isolated tiers with controlled communication
- **Private Subnets**: Database and sensitive components isolated

### Access Control
- **Bastion Host Pattern**: Web tier as controlled access point
- **No Direct DB Access**: Database access only through application tier
- **VPC Flow Logs**: Network traffic monitoring and analysis
- **CloudTrail**: API activity logging and audit trail

### Compliance Features
- **Data Isolation**: Separate environments for production and development
- **Audit Trail**: Comprehensive logging of all network activities
- **Encryption in Transit**: HTTPS/SSL termination at load balancer
- **Regular Security Reviews**: Automated compliance checking

## 💡 Cost Optimization Strategies

### NAT Gateway Optimization
- **Single NAT Gateway**: Shared across multiple private subnets
- **Placement Strategy**: NAT Gateway in public subnet for efficiency
- **Data Transfer**: Minimized cross-AZ data transfer costs

### Instance Right-Sizing
- **Development Environment**: Smaller instance types for cost savings
- **Production Environment**: Optimized instance types for performance
- **Reserved Instances**: Long-term cost savings for stable workloads

## 🎓 Learning Outcomes

This project demonstrates practical experience with:
- ✅ **VPC Design Principles** - Multi-tier architecture implementation
- ✅ **Network Security** - Security groups and NACLs configuration
- ✅ **VPC Peering** - Cross-VPC communication setup
- ✅ **Route Table Management** - Complex routing scenarios
- ✅ **Internet Gateway & NAT** - Public and private subnet connectivity
- ✅ **Network Troubleshooting** - Connectivity and security debugging
- ✅ **AWS Best Practices** - Enterprise-grade network design

## 🚨 Troubleshooting Guide

### Common Issues & Solutions

#### Instance Cannot Access Internet
```bash
# Check route table associations
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxxxx"

# Verify NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxxxxx"

# Check security group outbound rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx
```

#### VPC Peering Connection Issues
```bash
# Verify peering connection status
aws ec2 describe-vpc-peering-connections

# Check route table entries for peering
aws ec2 describe-route-tables --filters "Name=route.destination-cidr-block,Values=10.1.0.0/16"

# Validate security group rules for cross-VPC access
aws ec2 describe-security-groups --filters "Name=ip-permission.cidr,Values=10.1.0.0/16"
```

#### Security Group Connectivity Problems
```bash
# Test port connectivity
telnet instance-ip port-number

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# Verify NACL rules
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=vpc-xxxxxxxx"
```

## 📚 Documentation Links

- **[Complete GUI Implementation Guide](documentation/AWS-VPC-Case-Study-Solution.md)** - Step-by-step AWS Console instructions
- **[Architecture Deep Dive](documentation/architecture-overview.md)** - Technical architecture analysis
- **[Security Implementation](documentation/security-analysis.md)** - Comprehensive security breakdown
- **[Network Troubleshooting](troubleshooting/debugging-guide.md)** - Problem resolution guide
- **[Best Practices](troubleshooting/best-practices.md)** - AWS VPC optimization recommendations

## 🔗 Academic Context

**Course**: AWS Solutions Architect Training  
**Institution**: IntelliPaat  
**Module**: VPC and Network Architecture  
**Project Type**: Case Study Implementation  
**Focus Areas**: Multi-tier architecture, Network security, VPC peering

## 🤝 Contributing

Contributions and improvements are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/network-enhancement`)
3. Commit your changes (`git commit -am 'Add network enhancement'`)
4. Push to the branch (`git push origin feature/network-enhancement`)
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

**[Your Name]**  
📧 Email: [your.email@example.com](mailto:your.email@example.com)  
🔗 LinkedIn: [Your LinkedIn Profile](https://www.linkedin.com/in/yourprofile/)  
🎓 Course: AWS Solutions Architect Training

---

⭐ **Star this repository if it helped you understand AWS VPC architecture and networking!**

**Keywords**: AWS, VPC, Multi-Tier Architecture, Network Security, VPC Peering, Security Groups, NACLs, NAT Gateway, Route Tables, Network Isolation, Enterprise Networking