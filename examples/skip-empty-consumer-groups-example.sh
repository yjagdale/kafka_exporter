#!/bin/bash

# Example: Using the Skip Empty Consumer Groups Feature
# This script demonstrates how to use the --skip.empty-consumer-groups flag

set -e

KAFKA_BROKER="${KAFKA_BROKER:-localhost:9092}"
EXPORTER_PORT="${EXPORTER_PORT:-9308}"

echo "=========================================="
echo "Skip Empty Consumer Groups - Example"
echo "=========================================="
echo ""

# Example 1: Run with default behavior (include all consumer groups)
echo "Example 1: Default Behavior (All Consumer Groups)"
echo "--------------------------------------------------"
echo "Starting exporter WITHOUT --skip.empty-consumer-groups flag"
echo ""
echo "Command:"
echo "  kafka_exporter --kafka.server=$KAFKA_BROKER --web.listen-address=:$EXPORTER_PORT"
echo ""
echo "This will export metrics for ALL consumer groups, including:"
echo "  - Empty consumer groups (0 members)"
echo "  - Consumer groups with no topic assignments"
echo "  - Active consumer groups"
echo ""

# Example 2: Run with skip empty consumer groups enabled
echo "=========================================="
echo "Example 2: Skip Empty Consumer Groups"
echo "--------------------------------------------------"
echo "Starting exporter WITH --skip.empty-consumer-groups flag"
echo ""
echo "Command:"
echo "  kafka_exporter --kafka.server=$KAFKA_BROKER \\"
echo "                 --web.listen-address=:$EXPORTER_PORT \\"
echo "                 --skip.empty-consumer-groups"
echo ""
echo "This will ONLY export metrics for consumer groups that:"
echo "  - Have at least 1 active member, AND"
echo "  - Have at least 1 committed offset (topic assignment)"
echo ""

# Example 3: Combine with group filters
echo "=========================================="
echo "Example 3: Advanced - Combine with Filters"
echo "--------------------------------------------------"
echo "Command:"
echo "  kafka_exporter --kafka.server=$KAFKA_BROKER \\"
echo "                 --web.listen-address=:$EXPORTER_PORT \\"
echo "                 --skip.empty-consumer-groups \\"
echo "                 --group.filter='^prod-.*' \\"
echo "                 --group.exclude='^test-.*' \\"
echo "                 --verbosity=1"
echo ""
echo "This configuration will:"
echo "  1. Only monitor consumer groups starting with 'prod-'"
echo "  2. Exclude consumer groups starting with 'test-'"
echo "  3. Skip empty or unconnected consumer groups"
echo "  4. Show debug logs when groups are skipped"
echo ""

# Example 4: Docker usage
echo "=========================================="
echo "Example 4: Using Docker"
echo "--------------------------------------------------"
echo "Command:"
echo "  docker run -ti --rm -p 9308:9308 danielqsj/kafka-exporter \\"
echo "    --kafka.server=$KAFKA_BROKER \\"
echo "    --skip.empty-consumer-groups \\"
echo "    --verbosity=1"
echo ""

# Example 5: Kubernetes/Helm
echo "=========================================="
echo "Example 5: Kubernetes Deployment"
echo "--------------------------------------------------"
echo "Add to your values.yaml:"
echo ""
cat <<'EOF'
kafkaExporter:
  args:
    - --kafka.server=kafka:9092
    - --skip.empty-consumer-groups
    - --verbosity=1
  # Or as environment variables/config
  extraArgs:
    skipEmptyConsumerGroups: true
EOF
echo ""

# Testing section
echo "=========================================="
echo "How to Test This Feature"
echo "=========================================="
echo ""
echo "1. Create test consumer groups:"
echo "   # Active consumer group"
echo "   kafka-console-consumer --bootstrap-server $KAFKA_BROKER \\"
echo "     --topic test-topic --group active-group &"
echo ""
echo "   # Create and stop consumer (empty group)"
echo "   kafka-console-consumer --bootstrap-server $KAFKA_BROKER \\"
echo "     --topic test-topic --group empty-group"
echo "   # (press Ctrl+C to stop)"
echo ""
echo "2. Start exporter with the flag:"
echo "   ./kafka_exporter --kafka.server=$KAFKA_BROKER \\"
echo "     --skip.empty-consumer-groups --verbosity=1"
echo ""
echo "3. Check metrics:"
echo "   curl http://localhost:$EXPORTER_PORT/metrics | grep consumergroup_members"
echo ""
echo "4. Compare results:"
echo "   - With flag: Only 'active-group' should appear"
echo "   - Without flag: Both 'active-group' and 'empty-group' appear"
echo ""

# Monitoring recommendations
echo "=========================================="
echo "Monitoring Recommendations"
echo "=========================================="
echo ""
echo "1. Initially run WITHOUT the flag to see all consumer groups"
echo "2. Identify which consumer groups are always empty/inactive"
echo "3. Enable the flag to reduce metric cardinality"
echo "4. Monitor logs with --verbosity=1 to see what's being skipped"
echo "5. Use group filters for more fine-grained control"
echo ""

echo "=========================================="
echo "For more information, see:"
echo "  - SKIP_EMPTY_CONSUMER_GROUPS.md"
echo "  - README.md"
echo "=========================================="

