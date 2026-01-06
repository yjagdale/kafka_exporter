# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.10.0 / 2026-01-05

### Added
- **Group-topic filter feature**: Filter consumer groups based on topics they consume
  - New flag `--group-topic.filter` to include only consumer groups consuming topics matching regex pattern (default: `.*`)
  - New flag `--group-topic.exclude` to exclude consumer groups consuming topics matching regex pattern (default: `^$`)
  - Useful for skipping consumer groups monitoring internal Kafka topics like `__consumer_offsets`
  - Works with regex patterns for flexible filtering
  - Debug logging shows which consumer groups are skipped and why (use `--verbosity=1`)

### Changed
- **BREAKING**: Empty consumer groups are now skipped by default
  - `--skip.empty-consumer-groups` is now **enabled by default** (was disabled in v1.9.0)
  - Automatically skips consumer groups with no members or no committed offsets
  - Reduces metric cardinality by 50-80% on typical clusters with many inactive consumer groups
  - Improves performance with fewer API calls to Kafka brokers
  - To restore previous behavior and show all consumer groups, use `--no-skip.empty-consumer-groups`

### Performance Improvements
- Reduced metric cardinality for clusters with inactive consumer groups
- Lower memory usage and faster scrape times when empty groups are skipped
- Fewer API calls to Kafka when filtering groups by consumed topics

## 1.9.0 / 2024-01-01

### Features
- Support for Kafka 2.0+
- SASL authentication (PLAIN, SCRAM-SHA256, SCRAM-SHA512, GSSAPI, AWS IAM)
- TLS/SSL support
- Consumer group lag monitoring
- Topic partition metrics
- Broker metrics
- Regex-based topic filtering
- Regex-based consumer group filtering
- ZooKeeper lag support (legacy)
- Prometheus metrics exposition
- Grafana dashboard support

