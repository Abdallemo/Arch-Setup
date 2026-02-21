#!/usr/bin/env bash

FAILED=()
actions_todo=()

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

    local out_func="log"
    if declare -f "$1" > /dev/null; then
        out_func="$1"
        shift
    fi

    local cmd_str="$*"

    "$out_func" "Running: $cmd_str"

    "$@"
    local status=$?

    if [ $status -eq 0 ]; then
        log "Finished: $cmd_str"
    else
        err "Failed: $cmd_str (Exit: $status)"
        FAILED+=("$cmd_str")
    fi

    return $status
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
        notify-send "$title Failed" "Check ${app_name} for logs" --icon=dialog-error --app-name="$app_name"
        canberra-gtk-play -i dialog-error &
    fi
}

setcfg() {
    local key="$1"
    local sep="$2"
    local value="$3"
    local file="$4"
    local new_line="${key}${sep}${value}"

    if [[ -z "$key" || -z "$sep" || -z "$value" || -z "$file" ]];then
      err "Usage: setcfg [key] [seperator (eg. =,:)] [value] [source_file]"
      return 1

    fi
    [ ! -f "$file" ] && safe_run sudo touch "$file"

    if grep -q "^[[:space:]]*${key}${sep}" "$file"; then
        log "Updating '$key' in $file..."
        safe_run sudo sed -i "s|^[[:space:]]*$key.*$|$new_line|" "$file"
    else
        log "Adding '$key' to $file..."
        safe_run bash -c "echo '$new_line' | sudo tee -a '$file' > /dev/null"
    fi
}
getcfg() {
    local key=$1
    [[ -z "$key" ]] && return 1
    local locations=("/etc" "$HOME/.config" "/usr/share" "/usr/local/share")

    grep -rI "^[[:space:]]*${key}[=: ][^\$]" "${locations[@]}" 2>/dev/null
}

sysdrivers() {

    log "SYSTEM & KERNEL"
    {
        echo "Kernel: $(uname -rm)"
        lspci -k | grep -A 2 -i vga | sed -E 's/^\s*//'

        local rebar_size=$(lspci -v -s "$gpu_addr" | grep "Memory at" | grep "prefetchable" | grep -oE "size=[0-9]+[MG]" | head -n 1)
        [[ -n "$rebar_size" ]] && echo "Resizable BAR: [$rebar_size]" || echo "Resizable BAR: Hidden"


    } | column -t -s ":" | sed 's/^/  /'


    echo ""
    log "OPENGL (MESA)"
    if command -v glxinfo &> /dev/null; then
        glxinfo | grep -E "OpenGL version|Device" | sed -E 's/ string//; s/^\s*//' | column -t -s ":" | sed 's/^/  /'
    else
        warn "mesa-utils not installed"
    fi

    echo ""
    log "VULKAN"
    if command -v vulkaninfo &> /dev/null; then

        vulkaninfo --summary | grep -E "deviceName|driverName|driverInfo" | sed -E 's/^\s*//' | column -t -s "=" | sed 's/^/  /'
    else
        warn "vulkan-tools not installed"
    fi

    echo ""
    log "COMPUTE (ROCm/OpenCL)"
    if command -v rocminfo &> /dev/null; then
        rocminfo | grep "Marketing Name" | head -n 2 | sed -E 's/^\s*//' | column -t -s ":" | sed 's/^/  /'
    else
        err "ROCm/OpenCL runtime not detected"
    fi
}
