# Summary: Skip Empty Consumer Groups - Now Enabled by Default

## 🎯 Quick Summary

**The `--skip.empty-consumer-groups` feature is now ENABLED BY DEFAULT.**

Empty and unconnected consumer groups will be automatically skipped during scraping.

---

## ⚙️ What Changed

| Aspect | Before (v1.9.0) | After (v1.9.1+) |
|--------|----------------|----------------|
| **Default Behavior** | Export all consumer groups | Skip empty/unconnected groups |
| **Flag to Enable** | `--skip.empty-consumer-groups` | Not needed (enabled by default) |
| **Flag to Disable** | Not needed (disabled by default) | `--no-skip.empty-consumer-groups` |
| **Empty Groups** | ✅ Exported | ❌ Skipped |
| **Groups with No Offsets** | ✅ Exported | ❌ Skipped |
| **Active Groups** | ✅ Exported | ✅ Exported |

---

## 🚀 Action Required

### If You Want the New Behavior (Recommended)
**✅ No action required** - Simply upgrade and enjoy reduced metrics!

### If You Need the Old Behavior
**Add this flag:**
```bash
--no-skip.empty-consumer-groups
```

---

## 💡 Why This Change?

1. **Performance**: Reduces API calls to Kafka by default
2. **Cost**: Lower metric cardinality = lower storage costs
3. **Clarity**: Cleaner metrics focused on active consumers
4. **Best Practice**: Most users want to skip empty groups anyway

---

## 📊 Expected Impact

For a typical cluster with 100 consumer groups (where 80 are inactive):

### Metrics Reduction
- **Before**: ~1000 consumer group metrics exported
- **After**: ~200 consumer group metrics exported (80% reduction)

### Performance Improvement
- **Before**: 200 API calls to Kafka brokers
- **After**: 120 API calls to Kafka brokers (40% reduction)

---

## 🔧 Quick Migration Examples

### Keep New Behavior (Default)
```bash
# No changes needed
kafka_exporter --kafka.server=kafka:9092
```

### Restore Old Behavior
```bash
# Add the --no-skip flag
kafka_exporter --kafka.server=kafka:9092 --no-skip.empty-consumer-groups
```

### Docker
```bash
# New behavior (default)
docker run -p 9308:9308 danielqsj/kafka-exporter --kafka.server=kafka:9092

# Old behavior (show all groups)
docker run -p 9308:9308 danielqsj/kafka-exporter \
  --kafka.server=kafka:9092 \
  --no-skip.empty-consumer-groups
```

### Kubernetes
```yaml
# New behavior (default)
args:
  - --kafka.server=kafka:9092

# Old behavior (show all groups)
args:
  - --kafka.server=kafka:9092
  - --no-skip.empty-consumer-groups
```

---

## 🔍 How to Tell If Groups Are Being Skipped

### Enable Debug Logging
```bash
kafka_exporter --kafka.server=kafka:9092 --verbosity=1
```

### Look for These Log Messages
```
I0105 11:13:07 kafka_exporter.go:600] Skipping empty consumer group: old-consumer
I0105 11:13:07 kafka_exporter.go:615] Skipping consumer group with no topic assignments: inactive-group
```

### Check Metrics Count
```bash
# Before upgrade
curl -s http://localhost:9308/metrics | grep -c kafka_consumergroup_members

# After upgrade (should be lower)
curl -s http://localhost:9308/metrics | grep -c kafka_consumergroup_members
```

---

## 📚 Documentation

For more details, see:
- **Full User Guide**: `SKIP_EMPTY_CONSUMER_GROUPS.md`
- **Migration Guide**: `MIGRATION_GUIDE.md`
- **Technical Flow**: `DECISION_FLOW.md`
- **Implementation Details**: `FEATURE_SUMMARY.md`

---

## ✅ Checklist for Upgrading

- [ ] Understand the new default behavior
- [ ] Decide if you need to disable it (`--no-skip.empty-consumer-groups`)
- [ ] Update deployment configurations if needed
- [ ] Test in dev/staging first
- [ ] Update Grafana dashboards if necessary
- [ ] Update alerts if they depend on empty group metrics
- [ ] Monitor logs after upgrade

---

## 🆘 Need Help?

**Want old behavior?** → Add `--no-skip.empty-consumer-groups`

**See unexpected changes?** → Check logs with `--verbosity=1`

**Dashboards broken?** → See `MIGRATION_GUIDE.md` for solutions

**Questions?** → Open an issue with your configuration

---

**Change Date**: January 5, 2026  
**Version**: 1.9.1+  
**Breaking Change**: Yes (default behavior changed)  
**Easy Rollback**: Yes (add flag or downgrade)

---

## 🎯 Bottom Line

**For most users**: This is a positive change that improves performance and reduces costs automatically.

**If you need all groups**: Just add `--no-skip.empty-consumer-groups` to your configuration.

**Either way**: You have full control over the behavior!

