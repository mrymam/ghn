package config

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

type Config struct {
	Org     string `json:"org"`
	Polling string `json:"polling"`
}

func (c Config) PollInterval() time.Duration {
	d, err := time.ParseDuration(c.Polling)
	if err != nil || d < 10*time.Second {
		return 5 * time.Minute
	}
	return d
}

func configPath() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "ghn", "config.json")
}

func Load() Config {
	var c Config
	data, err := os.ReadFile(configPath())
	if err != nil {
		return c
	}
	json.Unmarshal(data, &c)
	return c
}

func Save(c Config) error {
	p := configPath()
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(p, data, 0644)
}
