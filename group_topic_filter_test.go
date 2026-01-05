package main

import (
	"regexp"
	"testing"
)

// TestGroupTopicFilterLogic tests the group-topic filtering logic
func TestGroupTopicFilterLogic(t *testing.T) {
	tests := []struct {
		name              string
		groupTopicFilter  string
		groupTopicExclude string
		consumedTopics    []string
		shouldSkip        bool
	}{
		{
			name:              "No filter - include all",
			groupTopicFilter:  ".*",
			groupTopicExclude: "^$",
			consumedTopics:    []string{"orders", "payments"},
			shouldSkip:        false,
		},
		{
			name:              "Exclude internal topic - match",
			groupTopicFilter:  ".*",
			groupTopicExclude: "^__.*",
			consumedTopics:    []string{"orders", "__consumer_offsets"},
			shouldSkip:        true,
		},
		{
			name:              "Exclude internal topic - no match",
			groupTopicFilter:  ".*",
			groupTopicExclude: "^__.*",
			consumedTopics:    []string{"orders", "payments"},
			shouldSkip:        false,
		},
		{
			name:              "Filter prod topics - match",
			groupTopicFilter:  "^prod-.*",
			groupTopicExclude: "^$",
			consumedTopics:    []string{"prod-orders"},
			shouldSkip:        false,
		},
		{
			name:              "Filter prod topics - no match",
			groupTopicFilter:  "^prod-.*",
			groupTopicExclude: "^$",
			consumedTopics:    []string{"dev-orders"},
			shouldSkip:        true,
		},
		{
			name:              "Exclude wins over filter",
			groupTopicFilter:  "^prod-.*",
			groupTopicExclude: ".*-internal$",
			consumedTopics:    []string{"prod-internal"},
			shouldSkip:        true,
		},
		{
			name:              "Multiple topics - one matches filter",
			groupTopicFilter:  "^important-.*",
			groupTopicExclude: "^$",
			consumedTopics:    []string{"normal-topic", "important-orders"},
			shouldSkip:        false,
		},
		{
			name:              "Multiple topics - one matches exclude",
			groupTopicFilter:  ".*",
			groupTopicExclude: "^private-.*",
			consumedTopics:    []string{"public-topic", "private-data"},
			shouldSkip:        true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			groupTopicFilter := regexp.MustCompile(tt.groupTopicFilter)
			groupTopicExclude := regexp.MustCompile(tt.groupTopicExclude)

			shouldSkipGroup := false
			hasMatchingTopic := false

			for _, topic := range tt.consumedTopics {
				if groupTopicFilter.MatchString(topic) {
					hasMatchingTopic = true
				}
				if groupTopicExclude.MatchString(topic) {
					shouldSkipGroup = true
					break
				}
			}

			if groupTopicFilter.String() != ".*" && !hasMatchingTopic {
				shouldSkipGroup = true
			}

			if shouldSkipGroup != tt.shouldSkip {
				t.Errorf("Expected shouldSkip=%v, got %v", tt.shouldSkip, shouldSkipGroup)
			}
		})
	}
}

// TestExporterGroupTopicFilterInitialization tests that filters are initialized
func TestExporterGroupTopicFilterInitialization(t *testing.T) {
	opts := kafkaOpts{
		uri:                     []string{"localhost:9092"},
		kafkaVersion:            "2.0.0",
		metadataRefreshInterval: "30s",
	}

	exporter, err := NewExporter(opts, ".*", "^$", ".*", "^$", "^prod-.*", "^__.*")
	if err != nil {
		t.Logf("Cannot create exporter (Kafka may not be available): %v", err)
		return
	}
	defer exporter.client.Close()

	if exporter.groupTopicFilter.String() != "^prod-.*" {
		t.Errorf("Expected groupTopicFilter pattern %q, got %q", "^prod-.*", exporter.groupTopicFilter.String())
	}

	if exporter.groupTopicExclude.String() != "^__.*" {
		t.Errorf("Expected groupTopicExclude pattern %q, got %q", "^__.*", exporter.groupTopicExclude.String())
	}
}
