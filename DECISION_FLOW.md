# Skip Empty Consumer Groups - Decision Flow

## Feature Decision Tree

```
┌─────────────────────────────────────────┐
│  Consumer Group Discovery               │
│  (List all groups from Kafka)           │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│  Apply Group Filters                    │
│  - Match group.filter regex             │
│  - Exclude group.exclude regex          │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│  Describe Consumer Group                │
│  (Get member count & metadata)          │
└───────────────┬─────────────────────────┘
                │
                ▼
        ┌───────────────┐
        │ Check: Error? │
        └───────┬───────┘
                │
        ┌───────┴────────┐
        │ Yes            │ No
        ▼                ▼
    [SKIP]    ┌─────────────────────────────────┐
              │ Check: skip-empty-consumer-     │
              │        groups flag enabled?     │
              └─────────┬───────────────────────┘
                        │
                ┌───────┴────────┐
                │ No             │ Yes
                ▼                ▼
         [CONTINUE]    ┌──────────────────────────┐
                       │ Check: Group has         │
                       │        members?          │
                       │ (len(group.Members) > 0) │
                       └─────────┬────────────────┘
                                 │
                        ┌────────┴────────┐
                        │ No              │ Yes
                        ▼                 ▼
                    [SKIP]         [CONTINUE]
                    Log: "Skipping      │
                    empty consumer      │
                    group: {name}"      ▼
                                 ┌─────────────────────────────┐
                                 │ Fetch Consumer Group        │
                                 │ Offsets from Kafka          │
                                 └─────────┬───────────────────┘
                                           │
                                           ▼
                                 ┌─────────────────────────────┐
                                 │ Check: skip-empty-consumer- │
                                 │        groups flag enabled? │
                                 └─────────┬───────────────────┘
                                           │
                                  ┌────────┴────────┐
                                  │ No              │ Yes
                                  ▼                 ▼
                           [CONTINUE]    ┌──────────────────────────┐
                                         │ Check: Any partition has │
                                         │        offset != -1?     │
                                         └─────────┬────────────────┘
                                                   │
                                          ┌────────┴────────┐
                                          │ No              │ Yes
                                          ▼                 ▼
                                      [SKIP]         [CONTINUE]
                                      Log: "Skipping      │
                                      consumer group      │
                                      with no topic       │
                                      assignments:        │
                                      {name}"             ▼
                                                   ┌─────────────────────┐
                                                   │ Emit Metrics:       │
                                                   │ - Members count     │
                                                   │ - Current offsets   │
                                                   │ - Lag               │
                                                   │ - Lag sum           │
                                                   └─────────────────────┘
```

## Code Flow Explanation

### Phase 1: Discovery & Filtering
```go
// 1. List all consumer groups from broker
groups := broker.ListGroups()

// 2. Apply regex filters
for groupId in groups {
    if !groupFilter.Match(groupId) || groupExclude.Match(groupId) {
        continue  // Skip this group
    }
}

// 3. Describe groups to get details
describeGroups := broker.DescribeGroups(filteredGroupIds)
```

### Phase 2: Empty Member Check
```go
for group in describeGroups {
    // Check for errors
    if group.Err != 0 {
        continue  // Skip errored groups
    }
    
    // Check if empty (only when flag enabled)
    if skipEmptyConsumerGroups && len(group.Members) == 0 {
        klog.Debug("Skipping empty consumer group:", group.GroupId)
        continue  // Skip empty groups
    }
    
    // Proceed to fetch offsets...
}
```

### Phase 3: Topic Assignment Check
```go
// Fetch offsets for the consumer group
offsetFetchResponse := broker.FetchOffset(group.GroupId)

// Check if group has any valid topic assignments (only when flag enabled)
if skipEmptyConsumerGroups {
    hasValidTopics := false
    for topic, partitions in offsetFetchResponse.Blocks {
        for partition, block in partitions {
            if block.Offset != -1 {
                hasValidTopics = true
                break
            }
        }
    }
    
    if !hasValidTopics {
        klog.Debug("Skipping consumer group with no topic assignments:", group.GroupId)
        continue  // Skip groups with no committed offsets
    }
}

// Emit metrics for this consumer group
```

## Example Scenarios

### Scenario 1: Active Consumer Group ✅
```
Group: "active-consumers"
Members: 3
Topics: 
  - orders (partition 0: offset 1000)
  - products (partition 0: offset 500)

Decision:
  - Has members? YES (3)
  - Has valid offsets? YES (1000, 500)
  
Result: METRICS EXPORTED
  kafka_consumergroup_members{consumergroup="active-consumers"} 3
  kafka_consumergroup_lag{consumergroup="active-consumers",topic="orders",partition="0"} 50
  kafka_consumergroup_lag{consumergroup="active-consumers",topic="products",partition="0"} 25
```

### Scenario 2: Empty Consumer Group (Flag Enabled) ❌
```
Group: "old-consumer"
Members: 0
Topics: None

Decision:
  - Has members? NO (0)
  
Result: SKIPPED (Phase 2)
  Log: "Skipping empty consumer group: old-consumer"
  No metrics exported
```

### Scenario 3: Consumer with No Offsets (Flag Enabled) ❌
```
Group: "new-consumer"
Members: 1
Topics:
  - test (partition 0: offset -1)
  - test (partition 1: offset -1)

Decision:
  - Has members? YES (1)
  - Has valid offsets? NO (all -1)
  
Result: SKIPPED (Phase 3)
  Log: "Skipping consumer group with no topic assignments: new-consumer"
  No metrics exported
```

### Scenario 4: Same Groups (Flag Disabled) ✅
```
Group: "old-consumer"
Members: 0

Group: "new-consumer"
Members: 1
Topics: offset -1

Decision:
  - Flag disabled, export all groups
  
Result: METRICS EXPORTED FOR ALL
  kafka_consumergroup_members{consumergroup="old-consumer"} 0
  kafka_consumergroup_members{consumergroup="new-consumer"} 1
  kafka_consumergroup_lag{consumergroup="new-consumer",topic="test",partition="0"} -1
```

## Performance Impact

### Without Flag (Default)
```
Consumer Groups Found: 100
  - Active: 20
  - Empty: 60
  - No offsets: 20

Metrics Exported: 100 groups × ~10 metrics = ~1000 metrics
API Calls: 100 DescribeGroups + 100 FetchOffset = 200 calls
```

### With Flag Enabled
```
Consumer Groups Found: 100
  - Active: 20 (exported)
  - Empty: 60 (skipped in phase 2)
  - No offsets: 20 (skipped in phase 3)

Metrics Exported: 20 groups × ~10 metrics = ~200 metrics
API Calls: 100 DescribeGroups + 20 FetchOffset = 120 calls
Reduction: 80% fewer metrics, 40% fewer API calls
```

## Debugging Tips

### Enable Debug Logging
```bash
kafka_exporter --kafka.server=kafka:9092 \
  --skip.empty-consumer-groups \
  --verbosity=1
```

### Check Logs for Skipped Groups
```bash
# Look for these log messages:
I0105 10:30:45 kafka_exporter.go:600] Skipping empty consumer group: old-consumer
I0105 10:30:45 kafka_exporter.go:615] Skipping consumer group with no topic assignments: inactive-group
```

### Verify Metrics Output
```bash
# Count consumer group metrics with and without flag
curl -s http://localhost:9308/metrics | grep -c "kafka_consumergroup_members"

# With flag: Lower count (only active groups)
# Without flag: Higher count (all groups)
```

## Integration Points

This feature integrates with:
1. **Group Filters** (`--group.filter`, `--group.exclude`) - Applied BEFORE empty check
2. **Offset Modes** (`--offset.show-all`) - Works with both modes
3. **Verbosity Logging** (`--verbosity`) - Shows what's being skipped
4. **All Auth Methods** - Works with SASL, TLS, Kerberos, AWS IAM
5. **All Kafka Versions** - Compatible with 0.10.1.0+

## Summary

The feature provides two checkpoint filters:
1. **Phase 2**: Skip if no members (empty group)
2. **Phase 3**: Skip if no valid offsets (no topic assignments)

Both checks are only active when `--skip.empty-consumer-groups` flag is set.
This maintains full backward compatibility while providing powerful filtering for production use.

