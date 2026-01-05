# Migration Guide: Skip Empty Consumer Groups (Default Enabled)

## 🔔 Important Notice

**As of version 1.9.1+**, the `--skip.empty-consumer-groups` feature is now **ENABLED BY DEFAULT**.

This means empty and unconnected consumer groups will automatically be skipped during metrics collection.

---

## 📊 What Changed?

### Before (v1.9.0 and earlier)
- All consumer groups were scraped by default
- Empty groups and groups with no offsets were included in metrics
- You needed to add `--skip.empty-consumer-groups` to filter them out

### After (v1.9.1+)
- Empty consumer groups are **automatically skipped** by default
- Only active consumer groups with committed offsets are scraped
- You need to add `--no-skip.empty-consumer-groups` to see all groups

---

## 🔄 Impact on Your Deployment

### Metric Changes You'll See

#### Before Update
```prometheus
# All consumer groups exported
kafka_consumergroup_members{consumergroup="active-group"} 3
kafka_consumergroup_members{consumergroup="empty-group"} 0
kafka_consumergroup_members{consumergroup="old-group"} 0
kafka_consumergroup_lag{consumergroup="empty-group",topic="test",partition="0"} -1
```

#### After Update
```prometheus
# Only active consumer groups exported
kafka_consumergroup_members{consumergroup="active-group"} 3
# empty-group and old-group are no longer exported
```

### Benefits of This Change

✅ **Reduced Metric Cardinality**: Fewer metrics = lower storage costs  
✅ **Better Performance**: Fewer API calls to Kafka brokers  
✅ **Cleaner Dashboards**: Focus on active consumer groups only  
✅ **Lower Memory Usage**: Less memory needed for metric storage

---

## 🛠️ Migration Scenarios

### Scenario 1: You Want the New Behavior (Default)

**Action Required**: None! ✅

Simply upgrade and the feature will be enabled automatically.

```bash
# No changes needed to your startup command
kafka_exporter --kafka.server=kafka:9092
```

### Scenario 2: You Need the Old Behavior (Show All Groups)

**Action Required**: Add `--no-skip.empty-consumer-groups` flag

```bash
# Add this flag to restore old behavior
kafka_exporter --kafka.server=kafka:9092 \
  --no-skip.empty-consumer-groups
```

#### Docker
```bash
docker run -p 9308:9308 danielqsj/kafka-exporter \
  --kafka.server=kafka:9092 \
  --no-skip.empty-consumer-groups
```

#### Kubernetes/Helm
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka-exporter
spec:
  template:
    spec:
      containers:
      - name: kafka-exporter
        image: danielqsj/kafka-exporter:latest
        args:
        - --kafka.server=kafka:9092
        - --no-skip.empty-consumer-groups  # Add this line
```

### Scenario 3: You Already Used `--skip.empty-consumer-groups`

**Action Required**: You can remove the flag (it's now redundant)

```bash
# Before
kafka_exporter --kafka.server=kafka:9092 --skip.empty-consumer-groups

# After (flag is now optional since it's the default)
kafka_exporter --kafka.server=kafka:9092
```

---

## 🔍 How to Verify the Change

### Step 1: Check Current Metrics Before Upgrade

```bash
curl http://localhost:9308/metrics | grep kafka_consumergroup_members | wc -l
# Note this number
```

### Step 2: Upgrade to New Version

```bash
# Pull new version
docker pull danielqsj/kafka-exporter:latest
# or rebuild from source
go build -o kafka_exporter .
```

### Step 3: Check Metrics After Upgrade

```bash
curl http://localhost:9308/metrics | grep kafka_consumergroup_members | wc -l
# This number should be lower (only active groups)
```

### Step 4: Enable Debug Logging to See What's Skipped

```bash
kafka_exporter --kafka.server=kafka:9092 --verbosity=1

# Look for log messages like:
# I0105 11:13:07 kafka_exporter.go:600] Skipping empty consumer group: old-consumer
# I0105 11:13:07 kafka_exporter.go:615] Skipping consumer group with no topic assignments: inactive-group
```

---

## 📋 Checklist for Upgrading

- [ ] Review which consumer groups are currently being monitored
- [ ] Decide if you want the new default behavior or need to disable it
- [ ] Update your deployment configuration if needed
- [ ] Test in a development/staging environment first
- [ ] Update Grafana dashboards if they reference empty consumer groups
- [ ] Update alerting rules if they depend on empty consumer group metrics
- [ ] Monitor logs after upgrade to see which groups are being skipped
- [ ] Verify Prometheus metrics are as expected

---

## 🚨 Potential Issues and Solutions

### Issue 1: Grafana Dashboard Shows "No Data"

**Cause**: Dashboard references consumer groups that are now being skipped

**Solution A** (Recommended): Update dashboard to only show active consumer groups
```promql
# Old query
kafka_consumergroup_lag{consumergroup="my-group"}

# New query (add filter for groups with members)
kafka_consumergroup_lag{consumergroup="my-group"} 
  and kafka_consumergroup_members{consumergroup="my-group"} > 0
```

**Solution B**: Disable the feature
```bash
--no-skip.empty-consumer-groups
```

### Issue 2: Alerts Firing About Missing Metrics

**Cause**: Alerts expect metrics from consumer groups that are now skipped

**Solution A** (Recommended): Update alerts to handle missing metrics
```yaml
# Old alert
- alert: ConsumerGroupLagHigh
  expr: kafka_consumergroup_lag > 1000
  
# New alert (don't alert if group doesn't exist)
- alert: ConsumerGroupLagHigh
  expr: |
    kafka_consumergroup_lag > 1000
    and kafka_consumergroup_members > 0
```

**Solution B**: Disable the feature
```bash
--no-skip.empty-consumer-groups
```

### Issue 3: Need to Monitor Specific Empty Consumer Group

**Cause**: You have a legitimate use case for monitoring an empty group

**Solutions**:
1. **Disable the feature** globally: `--no-skip.empty-consumer-groups`
2. **Use group filters** to force inclusion:
   ```bash
   --group.filter="^(important-empty-group|active-.*)$"
   ```
3. **Monitor the consumer group state** outside of this exporter

---

## 📈 Monitoring the Migration

### Recommended Metrics to Watch

```promql
# Number of consumer groups being scraped
count(kafka_consumergroup_members)

# Total metrics exported (should decrease after upgrade)
count({__name__=~"kafka_consumergroup.*"})

# Consumer groups with members
count(kafka_consumergroup_members > 0)
```

### Before/After Comparison

Create a temporary dashboard to compare:

```promql
# Consumer groups BEFORE upgrade (save this query result)
count(kafka_consumergroup_members)

# Consumer groups AFTER upgrade
count(kafka_consumergroup_members)

# Difference (should be the number of empty/unconnected groups)
```

---

## 🔒 Rollback Plan

If you need to rollback to the old behavior:

### Option 1: Add Flag (Keep New Version)
```bash
--no-skip.empty-consumer-groups
```

### Option 2: Downgrade to Previous Version
```bash
# Docker
docker pull danielqsj/kafka-exporter:1.9.0

# Or rebuild from previous tag
git checkout v1.9.0
go build -o kafka_exporter .
```

---

## ⏱️ Recommended Migration Timeline

### Week 1: Testing
- Deploy in dev/staging with default settings
- Monitor which consumer groups are being skipped
- Update dashboards and alerts as needed

### Week 2: Limited Production
- Deploy to a subset of production clusters
- Monitor for any issues
- Gather feedback from team

### Week 3: Full Production Rollout
- Deploy to all production clusters
- Continue monitoring
- Document any customizations needed

---

## 📞 Support

If you encounter issues during migration:

1. **Enable debug logging**: `--verbosity=1`
2. **Check which groups are being skipped**: Look for log messages
3. **Compare metrics before/after**: Use Prometheus queries
4. **Review this guide**: Ensure you've followed all steps
5. **Open an issue**: Include logs, configuration, and reproduction steps

---

## 📝 Example Migration Commands

### Ansible
```yaml
- name: Deploy Kafka Exporter
  command: >
    kafka_exporter
    --kafka.server={{ kafka_broker }}
    --no-skip.empty-consumer-groups  # Add if needed
```

### Docker Compose
```yaml
services:
  kafka-exporter:
    image: danielqsj/kafka-exporter:latest
    command:
      - --kafka.server=kafka:9092
      # - --no-skip.empty-consumer-groups  # Uncomment if needed
```

### Systemd
```ini
[Service]
ExecStart=/usr/local/bin/kafka_exporter \
  --kafka.server=kafka:9092 \
  --no-skip.empty-consumer-groups  # Add if needed
```

---

## ✅ Summary

**Default Behavior Changed**: Empty consumer groups are now skipped by default.

**To Keep Old Behavior**: Add `--no-skip.empty-consumer-groups`

**To Use New Behavior**: No action required

**Impact**: Reduced metrics, better performance, cleaner monitoring

**Rollback**: Easy - just add the flag or downgrade

---

**Last Updated**: January 5, 2026  
**Applies To**: Version 1.9.1 and later

