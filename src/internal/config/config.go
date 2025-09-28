package config

import (
	"encoding/json"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config holds the application configuration
type Config struct {
	Port          int    `json:"port" yaml:"port"`
	DBServiceAddr string `json:"db_service_addr" yaml:"db_service_addr"`
	MaxBatchSize  int    `json:"max_batch_size" yaml:"max_batch_size"`
	ValidateData  bool   `json:"validate_data" yaml:"validate_data"`
	LogLevel      string `json:"log_level" yaml:"log_level"`
}

// LoadFromFile loads configuration from a file
func LoadFromFile(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	cfg := &Config{}

	// Try to parse as YAML first
	if err := yaml.Unmarshal(data, cfg); err == nil {
		return cfg, nil
	}

	// Try JSON if YAML fails
	if err := json.Unmarshal(data, cfg); err == nil {
		return cfg, nil
	}

	return nil, fmt.Errorf("failed to parse config file as YAML or JSON")
}

// Validate checks if the configuration is valid
func (c *Config) Validate() error {
	if c.Port <= 0 || c.Port > 65535 {
		return fmt.Errorf("invalid port: %d", c.Port)
	}

	if c.MaxBatchSize < 0 {
		return fmt.Errorf("invalid max_batch_size: %d", c.MaxBatchSize)
	}

	return nil
}

// SetDefaults sets default values for empty fields
func (c *Config) SetDefaults() {
	if c.Port == 0 {
		c.Port = 50051
	}

	if c.MaxBatchSize == 0 {
		c.MaxBatchSize = 100
	}

	if c.LogLevel == "" {
		c.LogLevel = "info"
	}
}