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
