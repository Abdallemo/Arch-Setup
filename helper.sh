#!/usr/bin/env bash

FAILED=()

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo -e "\e[32m [$(current_time -t)] $* \e[0m"
}

warn() {
    echo -e "\e[33m [$(current_time -t)] $* \e[0m" >&2
}

err() {
    echo -e "\e[31m [$(current_time -t)] $* \e[0m " >&2
}
info() {
    echo -e "\e[34m [$(current_time -t)] $* \e[0m " >&2
}

make_tmp() {
    mktemp --suffix=".$1"
}

current_time(){
    case "$1" in
        -t|--timestamp)
            date +"%H:%M:%S"
            shift
        ;;
        -*)
            err "Unknown option: $1"
            return 1
        ;;
        *)
            date +%Y%m%d_%H%M%S
            ;;

    esac

}

link() {
  src="$1"
  dst="$2"
  if [[ -z "$src" || -z "$dst" ]]; then
      err "Usage: link <source_file> <dest_path>"
      return 1
  fi
  if [[ ! -f "$src" ]]; then
      err "Source file '$src' does not exist."
      return 1
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  log "Linked $dst → $src"
}

safe_run() {
  "$@" || FAILED+=("$*")
}

alert() {
    local title="$1"
    local msg="$2"
    local exit_code="${3:-0}"
    local app_name="${4:-Shell}"

    if (( exit_code == 0 )); then
        notify-send "$title" "$msg" --icon=video-x-generic --app-name="$app_name"
        canberra-gtk-play -i message-new-instant &
    else
        notify-send "$title Failed" "Check terminal for logs" --icon=dialog-error --app-name="$app_name"
        canberra-gtk-play -i dialog-error &
    fi
}
