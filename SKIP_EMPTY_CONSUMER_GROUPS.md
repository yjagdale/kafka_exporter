# Skip Empty Consumer Groups Feature

## Overview

This feature allows you to skip scraping consumer groups that are:
1. **Empty** (have no active members)
2. **Not connected to any topics** (have no committed offsets)

This can help reduce the number of metrics exported and improve performance when you have many inactive or orphaned consumer groups.

## Use Cases

- **Clean metrics**: Only expose metrics for actively used consumer groups
- **Performance**: Reduce the number of metrics when you have many inactive consumer groups
- **Cost reduction**: Lower metrics storage costs by filtering out unused consumer groups
- **Monitoring focus**: Focus on consumer groups that are actually consuming data

## Default Behavior

**This feature is ENABLED by default** (as of v1.9.1+). Empty and unconnected consumer groups are automatically skipped.

### To Disable (Show All Consumer Groups)

If you want to see ALL consumer groups including empty ones:

```bash
kafka_exporter --kafka.server=kafka:9092 --no-skip.empty-consumer-groups
```

Or using Docker:

```bash
docker run -ti --rm -p 9308:9308 danielqsj/kafka-exporter \
  --kafka.server=kafka:9092 \
  --no-skip.empty-consumer-groups
```

## Behavior

### Default Behavior (Enabled by Default)

The exporter will **skip** consumer groups if:
- The consumer group has **zero members** (no active consumers), OR
- The consumer group has **no committed offsets** for any topic (all offsets are -1)

### When Explicitly Disabled (`--no-skip.empty-consumer-groups`)

The exporter will collect metrics for **all** consumer groups, including:
- Empty consumer groups
- Consumer groups with no topic assignments
- Inactive or orphaned consumer groups

## Examples

### Example 1: Active Consumer Group (Always Included)

```
Consumer Group: active-consumers
Members: 3
Topics: orders (offset: 1000), products (offset: 500)
Result: ✅ Metrics exported (regardless of flag setting)
```

### Example 2: Empty Consumer Group (Skipped When Flag Enabled)

```
Consumer Group: old-consumer
Members: 0
Topics: None (no committed offsets)
Result: 
  - With --skip.empty-consumer-groups: ❌ Skipped
  - Without flag: ✅ Metrics exported
```

### Example 3: Consumer Group with Members but No Offsets

```
Consumer Group: new-consumer
Members: 2
Topics: None (offset: -1 for all topics)
Result:
  - With --skip.empty-consumer-groups: ❌ Skipped (no valid offsets)
  - Without flag: ✅ Metrics exported
```

## Metrics Impact

### Before (without flag)

```prometheus
kafka_consumergroup_members{consumergroup="old-consumer"} 0
kafka_consumergroup_members{consumergroup="active-consumer"} 3
kafka_consumergroup_lag{consumergroup="old-consumer",topic="test",partition="0"} -1
kafka_consumergroup_lag{consumergroup="active-consumer",topic="test",partition="0"} 100
```

### After (with --skip.empty-consumer-groups)

```prometheus
kafka_consumergroup_members{consumergroup="active-consumer"} 3
kafka_consumergroup_lag{consumergroup="active-consumer",topic="test",partition="0"} 100
```

Notice that metrics for `old-consumer` are not exported when the flag is enabled.

## Logging

When the feature is enabled and consumer groups are skipped, you'll see debug log messages:

```
I0105 10:30:45.123456 1 kafka_exporter.go:600] Skipping empty consumer group: old-consumer
I0105 10:30:45.123789 1 kafka_exporter.go:615] Skipping consumer group with no topic assignments: inactive-group
```

To see these messages, increase the verbosity level:

```bash
kafka_exporter --kafka.server=kafka:9092 \
  --skip.empty-consumer-groups \
  --verbosity=1
```

## Configuration Reference

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--skip.empty-consumer-groups` | boolean | `true` | If true, do not scrape consumer groups that are empty or not connected to any topics (enabled by default) |
| `--no-skip.empty-consumer-groups` | boolean | - | Explicitly disable the feature to show all consumer groups including empty ones |

## Best Practices

1. **Use default for production** - Feature is enabled by default to reduce metric cardinality
2. **Disable for development/debugging** if you need to see all consumer groups:
   ```bash
   --no-skip.empty-consumer-groups
   ```
3. **Combine with group filters** for more granular control:
   ```bash
   --group.filter="^prod-.*" \
   --group.exclude="^test-.*"
   ```
4. **Monitor logs** initially to ensure expected consumer groups aren't being skipped:
   ```bash
   --verbosity=1
   ```

## Technical Details

### Implementation

The feature adds two checks in the consumer group metrics collection:

1. **Empty Member Check**: Before fetching offsets, check if `len(group.Members) == 0`
2. **Valid Offset Check**: After fetching offsets, verify at least one partition has offset != -1

### Performance Impact

- **Reduced API calls**: Fewer offset fetch requests to Kafka brokers
- **Lower memory usage**: Fewer metrics stored in memory before export
- **Faster scrapes**: Less time spent processing inactive consumer groups

### Compatibility

- Works with all Kafka versions supported by the exporter (0.10.1.0+)
- Compatible with all authentication mechanisms (SASL, TLS, Kerberos, AWS IAM)
- Can be used alongside all other exporter features

## Troubleshooting

### Consumer group is being skipped unexpectedly

**Check 1**: Verify the consumer group has active members:
```bash
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
  --describe --group your-group
```

**Check 2**: Verify the consumer group has committed offsets:
```bash
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
  --describe --group your-group --offsets
```

**Solution**: If the consumer group should be included, ensure it has:
- At least one active member, OR
- At least one committed offset (offset != -1)

### I want to include some empty consumer groups but skip others

Use the group filter flags in combination:

```bash
--skip.empty-consumer-groups \
--group.filter="^(important-group|critical-group|prod-.*)$" \
--group.exclude="^temp-.*"
```

This will:
1. Skip all empty/unconnected consumer groups
2. Only consider groups matching the filter regex
3. Exclude groups matching the exclude regex

## Related Configuration

- `--group.filter`: Regex to include specific consumer groups
- `--group.exclude`: Regex to exclude specific consumer groups
- `--offset.show-all`: Show offsets for all partitions vs only assigned partitions

## Version

This feature was added in version 1.9.1+

