package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func applyConfigurations() error {
	Log("--- Applying System and User Configurations ---")

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("could not get user home directory: %w", err)
	}

	rootDir, err := filepath.Abs("..")
	if err != nil {
		return fmt.Errorf("could not get project root directory: %w", err)
	}
	dotfilesDir := filepath.Join(rootDir, "dotfiles")

	steps := []func(string, string, string) error{
		setupBaseSymlinks,
		func(h, d, r string) error { return setupNvim(h) },
		func(h, d, r string) error { return setupPgService(h, d) },
		func(h, d, r string) error { return setupSimpleConfigs(h, d) },
		func(h, d, r string) error { return setEnvironmentVariables(h) },
		func(h, d, r string) error { return setupGitConfig() },
		func(h, d, r string) error { return setupDaVinciResolve(h, d) },
	}

	for _, step := range steps {
		if err := step(homeDir, dotfilesDir, rootDir); err != nil {
			// Log the error but continue with the next steps
			Err(fmt.Sprintf("A configuration step failed: %v", err))
		}
	}

	Log("--- System and User Configurations Complete ---")
	return nil
}

// symlink handles the core logic of creating a symbolic link.
func symlink(source, dest string) error {
	if lstat, err := os.Lstat(dest); err == nil {
		if lstat.Mode()&os.ModeSymlink == 0 {
			if promptUser(fmt.Sprintf("'%s' exists and is not a symlink. Replace it?", dest)) {
				backupName := dest + ".bak"
				Log(fmt.Sprintf("Backing up '%s' to '%s'", dest, backupName))
				if err := os.Rename(dest, backupName); err != nil {
					return fmt.Errorf("failed to backup '%s': %w", dest, err)
				}
			} else {
				Log(fmt.Sprintf("Skipping '%s'.", dest))
				return nil
			}
		} else {
			if err := os.Remove(dest); err != nil {
				return fmt.Errorf("failed to remove existing symlink '%s': %w", dest, err)
			}
		}
	}

	Log(fmt.Sprintf("Linking '%s' to '%s'", source, dest))
	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		return err
	}
	return os.Symlink(source, dest)
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func copyDir(src, dst string) error {
	if err := os.MkdirAll(dst, 0755); err != nil {
		return err
	}
	entries, err := os.ReadDir(src)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		srcPath := filepath.Join(src, entry.Name())
		dstPath := filepath.Join(dst, entry.Name())
		if entry.IsDir() {
			if err := copyDir(srcPath, dstPath); err != nil {
				return err
			}
		} else {
			if err := copyFile(srcPath, dstPath); err != nil {
				return err
			}
		}
	}
	return nil
}

func setupBaseSymlinks(homeDir, dotfilesDir, rootDir string) error {
	Log("Setting up base symlinks (.zshrc, common.sh)...")
	if err := symlink(filepath.Join(dotfilesDir, ".zshrc"), filepath.Join(homeDir, ".zshrc")); err != nil {
		return err
	}
	zshScriptsDir := filepath.Join(homeDir, ".config", "zsh_scripts")
	if err := symlink(filepath.Join(dotfilesDir, "common.sh"), filepath.Join(zshScriptsDir, "common.sh")); err != nil {
		return err
	}
	return symlink(filepath.Join(rootDir, "helper.sh"), filepath.Join(zshScriptsDir, "helper.sh"))
}

func setupNvim(homeDir string) error {
	Log("Setting up NeoVim config...")
	nvimDir := filepath.Join(homeDir, ".config", "nvim")
	if fileExists(nvimDir) {
		if !promptUser("Nvim config already exists. Replace it with a fresh clone?") {
			Log("Skipping nvim setup.")
			return nil
		}
		if err := os.RemoveAll(nvimDir); err != nil {
			return fmt.Errorf("failed to remove existing nvim config: %w", err)
		}
	}
	return run("git", "clone", "https://github.com/Abdallemo/neovim-setup.git", nvimDir)
}

func setupPgService(homeDir, dotfilesDir string) error {
	Log("Setting up pg_service config...")
	src := filepath.Join(dotfilesDir, "pg_service")
	dest := filepath.Join(homeDir, ".config", "pg_service")
	if fileExists(dest) {
		if !promptUser("pg_service config already exists. Replace it?") {
			Log("Skipping pg_service setup.")
			return nil
		}
		os.RemoveAll(dest)
	}
	Log(fmt.Sprintf("Copying '%s' to '%s'", src, dest))
	return copyDir(src, dest)
}

func setupSimpleConfigs(homeDir, dotfilesDir string) error {
	Log("Setting up Kitty and MangoHud configs...")
	if err := symlink(filepath.Join(dotfilesDir, "kitty"), filepath.Join(homeDir, ".config", "kitty")); err != nil {
		return err
	}
	return symlink(filepath.Join(dotfilesDir, "MangoHud"), filepath.Join(homeDir, ".config", "MangoHud"))
}

func setEnvironmentVariables(homeDir string) error {
	Log("Setting system-wide environment variables...")
	appendAsRoot := func(file, line string) error {
		return runInBash(fmt.Sprintf("echo '%s' | sudo tee -a %s > /dev/null", line, file))
	}
	writeAsRoot := func(file, content string) error {
		return runInBash(fmt.Sprintf("echo '%s' | sudo tee %s > /dev/null", content, file))
	}

	Log("Writing to /etc/environment (requires sudo)...")
	appendAsRoot("/etc/environment", "GTK_USE_PORTAL=1")
	appendAsRoot("/etc/environment", "MANGOHUD=1")

	pgFile := "/etc/profile.d/pg.sh"
	Log(fmt.Sprintf("Writing to %s (requires sudo)...", pgFile))
	pgContent := fmt.Sprintf("export PGSERVICEFILE=%s", filepath.Join(homeDir, ".config", "pg_service", ".pg_service.conf"))
	return writeAsRoot(pgFile, pgContent)
}

func setupGitConfig() error {
	Log("Checking git global config...")

	checkAndSet := func(key, value string) {

		output, err := exec.Command("git", "config", "--global", key).Output()

		if err != nil || len(bytes.TrimSpace(output)) == 0 {
			Log(fmt.Sprintf("Setting git global config: %s = %s", key, value))
			run("git", "config", "--global", key, value)
		} else {
			Log(fmt.Sprintf("Git config '%s' is already set to: %s", key, strings.TrimSpace(string(output))))
		}
	}

	checkAndSet("user.name", "Abdallemo")
	checkAndSet("user.email", "learn3038it@gmail.com")

	return nil
}

func setupDaVinciResolve(homeDir, dotfilesDir string) error {
	Log("Setting up DaVinci Resolve with Distrobox...")
	container := "davinci-fedora"

	if err := run("distrobox-create", "--name", container, "--image", "fedora:42", "--yes"); err != nil {
		Warn("Distrobox container creation failed. Skipping DaVinci setup.")
		return nil
	}

	deps := []string{"alsa-plugins-pulseaudio", "libxcrypt-compat", "mesa-libGLU"}
	args := []string{"enter", container, "--", "sudo", "dnf", "install", "-y"}
	args = append(args, deps...)
	if err := run("distrobox", args...); err != nil {
		Warn("Failed to install dependencies in container. DaVinci may not work.")
	}

	iconDest := filepath.Join(homeDir, ".local", "share", "icons", "davinci-resolve.png")
	desktopDest := filepath.Join(homeDir, ".local", "share", "applications", "resolve.desktop")
	copyFile(filepath.Join(dotfilesDir, "davinci_conf", "davinci-resolve.png"), iconDest)
	copyFile(filepath.Join(dotfilesDir, "davinci_conf", "resolve.desktop"), desktopDest)

	content, err := os.ReadFile(desktopDest)
	if err == nil {
		newContent := strings.Replace(string(content), "Icon=", "Icon="+iconDest, 1)
		os.WriteFile(desktopDest, []byte(newContent), 0644)
	}
	run("update-desktop-database", filepath.Join(homeDir, ".local/share/applications"))

	todos = append(todos,
		"For DaVinci Resolve: Download installer v20.3.2.",
		fmt.Sprintf("Enter container with: distrobox enter %s", container),
		"Run the DaVinci_Resolve_20.3.2_Linux.run installer inside the container.",
		"After install, run these commands inside the container:",
		"  sudo mkdir -p /opt/resolve/libs/disabled-libraries",
		"  sudo mv /opt/resolve/libs/libglib-2.0.so* /opt/resolve/libs/disabled-libraries/",
		"  sudo mv /opt/resolve/libs/libgio-2.0.so* /opt/resolve/libs/disabled-libraries/",
		"  sudo mv /opt/resolve/libs/libgmodule-2.0.so* /opt/resolve/libs/disabled-libraries/",
	)
	Warn("DaVinci Resolve setup requires several manual steps.")
	return nil
}
