#!/usr/bin/env bash

source ./helper.sh

log "Starting Arch system setup..."

safe_run ./packages.sh
safe_run ./config.sh
safe_run ./services.sh

echo
if [ ${#FAILED[@]} -ne 0 ]; then
  warn "Some steps failed:"
  printf ' - %s\n' "${FAILED[@]}"
else
  log "System setup completed successfully "
fi
