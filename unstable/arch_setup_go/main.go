package main

import (
	"fmt"
)

func main() {

	Log("Starting Arch system setup in Go...")

	if err := installPackagesAndTools(); err != nil {
		Err(fmt.Sprintf("Fatal error during package installation: %v", err))
		return
	}

	if err := applyConfigurations(); err != nil {
		Err(fmt.Sprintf("An error occurred during configuration: %v", err))
	}

	if err := setupServices(); err != nil {
		Err(fmt.Sprintf("An error occurred during service setup: %v", err))
	}

	if len(todos) > 0 {
		Warn("-------------------------------------------------")
		Warn("Manual actions are required to complete the setup:")
		for _, todo := range todos {
			fmt.Println(ColorYellow + "  - " + ColorReset + todo)
		}
		Warn("-------------------------------------------------")
	}

	Log("System setup completed.")
}
