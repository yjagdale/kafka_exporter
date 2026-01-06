# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Group-topic filter feature: Filter consumer groups based on topics they consume
  - New flag: `--group-topic.filter` to include consumer groups based on consumed topics
  - New flag: `--group-topic.exclude` to exclude consumer groups based on consumed topics
- Skip empty consumer groups by default
  - `--skip.empty-consumer-groups` is now enabled by default
  - Use `--no-skip.empty-consumer-groups` to show all consumer groups including empty ones

### Changed
- **BREAKING**: Empty consumer groups are now skipped by default (was disabled before)
  - Reduces metric cardinality by 50-80% on typical clusters
  - To restore previous behavior, use `--no-skip.empty-consumer-groups`

## [1.9.0] - Previous Release

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

[Unreleased]: https://github.com/danielqsj/kafka_exporter/compare/v1.9.0...HEAD
[1.9.0]: https://github.com/danielqsj/kafka_exporter/releases/tag/v1.9.0

