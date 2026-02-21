package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

// installPackagesAndTools is the main function for this file, orchestrating all installations.
func installPackagesAndTools() error {
	Log("--- Starting Package and Tool Installation ---")

	if err := installYay(); err != nil {
		return fmt.Errorf("failed to install yay: %w", err)
	}

	installAurPackages()

	if err := installWebdevTools(); err != nil {
		Err(fmt.Sprintf("Failed to install webdev tools: %s", err))
	}

	if err := installUv(); err != nil {
		Err(fmt.Sprintf("Failed to install uv: %s", err))
	}

	Log("--- Package and Tool Installation Complete ---")

	return nil
}

func installYay() error {

	if _, err := exec.LookPath("yay"); err == nil {
		Log("yay is already installed.")
		return nil
	}

	Log("Installing yay...")

	if err := run("sudo", "pacman", "-S", "--needed", "--noconfirm", "base-devel", "git"); err != nil {
		return err
	}

	yayDir, err := os.MkdirTemp("", "yay-build-")
	if err != nil {
		return fmt.Errorf("failed to create temp dir for yay build: %w", err)
	}
	defer os.RemoveAll(yayDir)
	Log(fmt.Sprintf("Using temporary directory for yay build: %s", yayDir))

	if err := run("git", "clone", "https://aur.archlinux.org/yay.git", yayDir); err != nil {
		return err
	}

	runInDir := func(dir string, name string, args ...string) error {
		Log(fmt.Sprintf("Running in %s: %s %s", dir, name, strings.Join(args, " ")))
		cmd := exec.Command(name, args...)
		cmd.Dir = dir
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	return runInDir(yayDir, "makepkg", "-si", "--noconfirm")
}

// installAurPackages installs all the packages listed in the 'packages' slice.
func installAurPackages() {
	Log(fmt.Sprintf("Attempting to install %d packages...", len(packages)))
	var failedPackages []string

	for _, pkg := range packages {

		Log(fmt.Sprintf("Installing: %s", pkg))
		if err := run("yay", "-S", "--needed", "--noconfirm", pkg); err != nil {
			Err(fmt.Sprintf("Failed to install package: %s", pkg))
			failedPackages = append(failedPackages, pkg)
		}
	}

	if len(failedPackages) > 0 {
		Warn("The following packages failed to install:")
		for _, pkg := range failedPackages {
			fmt.Println("  - " + pkg)
		}
	} else {
		Log("All packages handled successfully.")
	}
}

func installWebdevTools() error {
	Log("Installing global web development tools...")

	if err := run("yay", "-S", "--needed", "--noconfirm", "nodejs"); err != nil {
		return fmt.Errorf("failed to install nodejs for npm: %w", err)
	}

	return run("sudo", "npm", "install", "-g", "pnpm")
}

func installUv() error {
	Log("Installing uv...")

	resp, err := http.Get("https://astral.sh/uv/install.sh")
	if err != nil {
		return fmt.Errorf("failed to download uv installer: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status code while downloading uv installer: %s", resp.Status)
	}

	scriptFile, err := os.CreateTemp("", "uv-install-*.sh")
	if err != nil {
		return fmt.Errorf("failed to create temp file for uv installer: %w", err)
	}
	defer os.Remove(scriptFile.Name())

	_, err = io.Copy(scriptFile, resp.Body)
	if err != nil {
		return fmt.Errorf("failed to write uv installer to temp file: %w", err)
	}
	scriptFile.Close()

	Log(fmt.Sprintf("Executing uv installer from: %s", scriptFile.Name()))
	return run("sh", scriptFile.Name())
}
