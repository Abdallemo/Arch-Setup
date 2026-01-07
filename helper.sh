#!/usr/bin/env bash

FAILED=()

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  echo -e "[*] $1"
}

warn() {
  echo -e "[!] $1"
}

safe_run() {
  "$@" || FAILED+=("$*")
}
