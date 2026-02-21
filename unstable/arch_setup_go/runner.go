package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// ANSI color codes for logging.
const (
	ColorReset  = "\033[0m"
	ColorRed    = "\033[31m"
	ColorGreen  = "\033[32m"
	ColorYellow = "\033[33m"
	ColorBlue   = "\033[34m"
)

func Log(message string) {
	fmt.Println(ColorBlue + "==> " + ColorReset + message)
}

func Warn(message string) {
	fmt.Println(ColorYellow + "WARN: " + ColorReset + message)
}

func Err(message string) {
	fmt.Println(ColorRed + "ERROR: " + ColorReset + message)
}

// run executes a command, logs it, and streams its output to the console.
// It returns an error if the command fails.
func run(name string, args ...string) error {
	Log(fmt.Sprintf("Running: %s %s", name, strings.Join(args, " ")))

	cmd := exec.Command(name, args...)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("command failed: %s %s", name, strings.Join(args, " "))
	}
	return nil
}

// runInBash executes commands that need a shell environment
func runInBash(command string) error {
	return run("bash", "-c", command)
}

// fileExists checks if a file or directory exists.
func fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// promptUser asks a yes/no question to the user and returns their decision.
func promptUser(question string) bool {
	fmt.Print(ColorYellow + question + ColorReset + " (y/n) ")
	reader := bufio.NewReader(os.Stdin)
	char, _, err := reader.ReadRune()
	if err != nil {
		return false
	}
	return strings.ToLower(string(char)) == "y"
}
