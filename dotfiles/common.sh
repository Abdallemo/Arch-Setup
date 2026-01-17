yay-clean() {
    if [ -z "$1" ]; then
        echo "Usage: yayclean <package_name>"
        return 1
    fi
    local cache_dir="$HOME/.cache/yay/$1"
    if [ -d "$cache_dir" ]; then
        rm -rf "$cache_dir"
        echo "✓ Removed cache for: $1"
    else
        echo "✗ No cache folder found for: $1"
    fi
}

alert() {
    local title="$1"
    local msg="$2"
    local exit_code="${3:-0}"

    if [ "$exit_code" -eq 0 ]; then
        notify-send "$title" "$msg" --icon=video-x-generic --app-name="FFmpeg"
        canberra-gtk-play -i message-new-instant &
    else
        notify-send "$title Failed" "Check terminal for logs" --icon=dialog-error --app-name="FFmpeg"
        canberra-gtk-play -i dialog-error &
    fi
}

ff-gpu() {
    local log_level="error"
    local input=""
    local output=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                log_level="info"
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    output="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ff-gpu [-v] input_file output_name"
        return 1
    fi

    echo "Encoding $input to ${output}.mp4..."
    ffmpeg -hide_banner \
        -loglevel "$log_level" \
        -stats \
        -init_hw_device vaapi=va:/dev/dri/renderD128 \
        -hwaccel vaapi \
        -hwaccel_device va \
        -hwaccel_output_format vaapi \
        -i "$input" \
        -filter_hw_device va \
        -vf 'format=p010,hwupload' \
        -c:v hevc_vaapi \
        -profile:v main10 \
        -rc_mode CQP \
        -qp 22 \
        -c:a aac \
        -b:a 192k \
        "${output}.mp4"

        alert "GPU Encode" "$output.mp4" "$?"
}


ff-resolve() {
    local log_level="error"
    local input=""
    local output=""
    local bitrate="70M"

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose) log_level="info"; shift ;;
            -b|--bitrate)
                bitrate="$2"
                if [[ "$bitrate" =~ ^[0-9]+$ ]]; then bitrate="${bitrate}M"; fi
                shift 2
                ;;
            *)
                if [ -z "$input" ]; then input="$1"; else output="$1"; fi
                shift
                ;;
        esac
    done

    if [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ff-resolve-cpu [-b 50] input output"
        return 1
    fi

    echo "Converting $input to ${output}.mov (CPU MPEG-2)..."

    ffmpeg -hide_banner \
        -loglevel "$log_level" \
        -stats \
        -i "$input" \
        -c:v mpeg2video \
        -q:v 1 \
        -maxrate "$bitrate" \
        -bufsize 20M \
        -c:a pcm_s16le \
        "${output}.mov"

    local exit_status=$?
    alert "CPU Resolve Convert" "$output.mov" "$exit_status"
}

ff-resolve-pro() {
    local log_level="error"
    local input=""
    local output=""
    local profile="dnxhr_lb"

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                log_level="info"
                shift
                ;;
            -hq|--high-quality)
                profile="dnxhr_sq"
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    output="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ff-resolve [-v] [-lb] input_file output_name"
        echo "  -hq : Medium Bandwidth (smaller files, good for 1080p editing)"
        return 1
    fi

    echo "Converting $input to ${output}.mov for DaVinci Resolve..."
    echo "Profile: $profile"

    ffmpeg -hide_banner \
        -loglevel "$log_level" \
        -stats \
        -init_hw_device vaapi=va:/dev/dri/renderD128 \
        -hwaccel vaapi \
        -hwaccel_output_format yuv420p \
        -i "$input" \
        -c:v dnxhd \
        -profile:v "$profile" \
        -pix_fmt yuv422p \
        -c:a pcm_s16le \
        "${output}.mov"

    local exit_status=$?
    alert "Resolve Convert" "$output.mov" "$exit_status"
}

ff-cpu() {
    local log_level="error"
    local input=""
    local output=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                log_level="info"
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    output="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ff-slow [-v] input_file output_name"
        return 1
    fi

    echo "Encoding $input to ${output}.mp4 (CPU x264)..."
    ffmpeg -hide_banner \
    -loglevel "$log_level" \
    -stats \
    -i "$input" \
    -c:v libx264 \
    -crf 20 \
    -preset slow \
    -c:a aac \
    -b:a 192k \
    "${output}.mp4"
    local exit_status=$?
    alert "CPU Encode" "$output.mp4" "$exit_status"
}

ff-mp3() {
    local log_level="error"
    local input=""
    local output=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                log_level="info"
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    output="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ff-mp3 [-v] input_file output_name"
        return 1
    fi

    echo "Extracting audio from $input to ${output}.mp3..."
    ffmpeg -hide_banner \
    -loglevel "$log_level" \
    -stats \
    -i "$input" \
    -vn \
    -c:a libmp3lame \
    -q:a 2 \
    "${output}.mp3"
    local exit_status=$?
    alert "Audio Rip" "$output.mp3" "$exit_status"
}

gh-push(){
    local commit="$1"
    if [ -z "$commit" ]; then
        echo "Usage: gh-push \"message\""
        return 1
    fi

    git add . &&  git commit -m "$commit" &&  git push
}

db-bak() {
    local service="$1"
    local timestamp=$(date +%Y%m%d_%H%M)
    local file="backup_${service}_${timestamp}.sql"

    if [[ -z "$service" ]]; then
        echo "Error: Service name required."
        echo "Usage: db-bak <service_name>"
        return 1
    fi

    if [[ -f "$file" ]]; then
        echo "Error: Backup for this minute already exists ($file)."
        return 1
    fi

    echo "Dumping $service to $file..."

    if pg_dump --clean --if-exists --no-owner --no-privileges "service=${service}" > "$file"; then
        echo "Success: Created $file"
    else
        echo "Dump failed. Cleaning up empty file..."
        rm -f "$file"
        return 1
    fi
}

db-restore() {
    local service="$1"
    local file="$2"

    if [[ -z "$service" || -z "$file" ]]; then
        echo "Usage: db-restore <service_name> <backup_file.sql>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    echo "⚠️ Warning: This will overwrite data in service: $service"
    echo -n "Continue? (y/n): "
    read -r confirmation
    if [[ "$confirmation" != "y" ]]; then
        echo "Restore cancelled."
        return 0
    fi

    echo "Restoring $file to $service..."

    if psql "service=${service}" < "$file"; then
        echo "Success: $service has been restored from $file"
    else
        echo "Error: Restore failed."
        return 1
    fi
}
