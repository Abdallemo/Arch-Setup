#!/usr/bin/env bash

source ./helper.sh

log "Starting Arch system setup..."

safe_run source ./packages.sh
safe_run source ./config.sh
safe_run source ./services.sh


if [ ${#FAILED[@]} -ne 0 ]; then
  warn "Some steps failed:"
  err "${FAILED[@]}"
else
  log "System setup completed successfully "
fi

for action in "${actions_todo[@]}"; do
        warn "TODO: $action"
done
