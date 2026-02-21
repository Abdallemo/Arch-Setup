package main

import (
	"fmt"
	"os"
)

func setupServices() error {
	Log("--- Starting Service Configuration ---")

	if err := mysqlSetup(); err != nil {
		Err("MySQL setup failed. Continuing...")

	}
	if err := pgSetup(); err != nil {
		Err("PostgreSQL setup failed. Continuing...")
	}
	if err := redisSetup(); err != nil {
		Err("Redis setup failed. Continuing...")
	}
	if err := dskStreamingSetup(); err != nil {
		Err("Desktop Streaming setup failed. Continuing...")
	}
	if err := setupPhoneLink(); err != nil {
		Err("Phone Link setup failed. Continuing...")
	}

	Log("--- Service Configuration Complete ---")

	return nil
}

// enableService is a helper to enable and start a systemd service.
func enableService(serviceName string) error {
	Log(fmt.Sprintf("Enabling service: %s", serviceName))
	return run("sudo", "systemctl", "enable", "--now", serviceName)
}

func mysqlSetup() error {
	Log("Setting up MariaDB...")
	if err := enableService("mariadb"); err != nil {
		return err
	}

	if !fileExists("/var/lib/mysql/mysql") {
		Log("Initializing MariaDB data directory...")
		if err := run("sudo", "mariadb-install-db", "--user=mysql", "--basedir=/usr", "--datadir=/var/lib/mysql"); err != nil {
			return err
		}
	} else {
		Log("MariaDB data directory already exists.")
	}

	todos = append(todos, "Run 'sudo mariadb-secure-installation' to secure your MariaDB installation.")
	Warn("MariaDB setup requires manual intervention.")
	return nil
}

func pgSetup() error {
	Log("Setting up PostgreSQL...")

	pgDataDir := "/var/lib/postgres/data"
	dir, err := os.Open(pgDataDir)
	needsInit := false
	if os.IsNotExist(err) {
		needsInit = true
	} else if err == nil {
		_, err = dir.Readdirnames(1)
		if err != nil {
			needsInit = true
		}
		dir.Close()
	}

	if needsInit {
		Log("Initializing PostgreSQL data directory...")
		if err := run("sudo", "-u", "postgres", "initdb", "-D", pgDataDir); err != nil {
			return err
		}
	} else {
		Log("PostgreSQL data directory already exists.")
	}

	return enableService("postgresql")
}

func redisSetup() error {
	Log("Setting up Redis...")
	return enableService("redis")
}

func dskStreamingSetup() error {
	Log("Setting up desktop streaming (Tailscale & Sunshine)...")
	if err := enableService("tailscaled"); err != nil {
		return err
	}

	user := os.Getenv("USER")
	if user != "" && user != "root" {
		if err := run("sudo", "loginctl", "enable-linger", user); err != nil {
			Warn(fmt.Sprintf("Could not enable linger for user %s. Sunshine might not start on boot.", user))
		}

		if err := run("systemctl", "--user", "enable", "--now", "sunshine"); err != nil {
			Warn("Failed to enable sunshine user service. You may need to do it manually.")
		}
	} else {
		Warn("Could not determine user to enable Sunshine service for.")
	}

	todos = append(todos, "Run 'sudo tailscale up' to authenticate Tailscale.")
	return nil
}

func setupPhoneLink() error {
	Log("Setting up phone link (KDE Connect & scrcpy)...")
	if err := run("sudo", "firewall-cmd", "--zone=public", "--permanent", "--add-service=kdeconnect"); err != nil {
		Warn("Could not add firewall rule for KDE Connect.")
	} else {
		run("sudo", "firewall-cmd", "--reload")
	}

	todos = append(todos, "For scrcpy over WiFi: enable USB debugging, run 'adb tcpip 5555', then connect with 'scrcpy --tcpip=<PHONE_IP>:5555'.")
	return nil
}
