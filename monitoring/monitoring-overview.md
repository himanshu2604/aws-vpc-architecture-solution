# VPC Multi-Tier Architecture Monitoring

## 📊 Monitoring Overview

This monitoring setup provides comprehensive visibility into the VPC infrastructure health, performance, and security.

## 🎯 Key Metrics Monitored

### Infrastructure Health
- **NAT Gateway**: Error rates, packet drops, throughput
- **VPC Peering**: Connection status and traffic flow
- **Internet Gateway**: Data transfer metrics

### Instance Performance
- **EC2 Status Checks**: System and instance reachability
- **CPU Utilization**: Performance monitoring across tiers
- **Network Metrics**: Traffic patterns and bandwidth usage
- **Memory Usage**: Resource utilization tracking

### Network Security
- **VPC Flow Logs**: Traffic analysis and rejected connections
- **Security Group Activity**: Allowed/blocked traffic
- **Unusual Traffic Patterns**: Anomaly detection
- **Cross-VPC Communication**: Peering traffic monitoring

## 🚨 Critical Alarms

### High Priority
1. **NAT Gateway Errors** - Threshold: >10 errors/5min
2. **Instance Status Failures** - Any failed status check
3. **VPC Peering Issues** - Connection failures
4. **High CPU Usage** - >80% for 15 minutes

### Security Alerts
1. **High Rejected Traffic** - >100 rejects/5min  
2. **Unusual Network Activity** - >10K packets/5min
3. **Unauthorized Access Attempts** - Failed connection patterns

## 📈 Dashboards

### VPC-Multi-Tier-Monitoring Dashboard
- **Infrastructure Health**: NAT Gateway, VPC status
- **Instance Metrics**: CPU, memory, network for all tiers
- **Network Flow**: Traffic patterns between subnets
- **Security Events**: Rejected traffic and anomalies

## 🔍 Common Queries

### VPC Flow Logs Analysis
```sql
-- Top rejected source IPs
fields @timestamp, srcaddr, action
| filter action = "REJECT"
| stats count() by srcaddr
| sort count desc | limit 10

-- Database access patterns
fields @timestamp, srcaddr, dstaddr, dstport
| filter dstport = 3306
| stats count() by srcaddr

-- Cross-VPC peering traffic
fields @timestamp, srcaddr, dstaddr
| filter (srcaddr like /^10\.0\./ and dstaddr like /^10\.1\./)
   or (srcaddr like /^10\.1\./ and dstaddr like /^10\.0\./)
```

## 🔧 Setup Requirements

### IAM Permissions
- CloudWatch read/write access
- VPC Flow Logs creation permissions
- SNS topic creation and publishing

### Cost Considerations
- **VPC Flow Logs**: ~$0.50/GB ingested
- **CloudWatch Alarms**: $0.10/alarm/month
- **Custom Metrics**: $0.30/metric/month
- **Estimated Monthly Cost**: $15-25 for this setup

## 📋 Monitoring Checklist

### Daily Checks
- [ ] Review dashboard for any red metrics
- [ ] Check alarm status in CloudWatch
- [ ] Verify VPC peering connectivity

### Weekly Reviews
- [ ] Analyze VPC Flow Logs for security patterns
- [ ] Review instance performance trends
- [ ] Check alarm threshold effectiveness

### Monthly Tasks
- [ ] Review monitoring costs and optimize
- [ ] Update alarm thresholds based on trends
- [ ] Archive old logs as per retention policy

## 🎛️ Configuration Files

1. **`cloudwatch-dashboard.json`** - Dashboard configuration
2. **`vpc-flow-logs.json`** - Flow logs setup
3. **`cloudwatch-alarms.json`** - Alarm definitions

---

**Note**: Replace placeholder values (ACCOUNT_ID, instance IDs, etc.) with actual resource identifiers before deployment.
