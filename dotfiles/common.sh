source $HOME/.config/zsh_scripts/helper.sh

yay-clean() {
    if [ -z "$1" ]; then
        err "Usage: yayclean <package_name>"
        return 1
    fi
    local found=0

    for cache_dir in $(find "$HOME/.cache/yay" -maxdepth 1 -name "$1")
    do
        if [ -d "$cache_dir" ]
        then
            rm -rf "$cache_dir"
            log "✓ Removed cache for: $(basename "$cache_dir")"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        err "✗ No cache folder found for: $1"
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
                err "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        err "Usage: ff-gpu [-v] input_file"
        return 1
    fi

    output="$(current_time)_${input%.*}.mp4"

    log "Encoding $input to ${output}..."
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
        "$output"

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
                if [ -z "$input" ]; then input="$1"; fi
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        err "Usage: ff-resolve [-b 70] input "
        return 1
    fi

    output="$(current_time)_${input%.*}.mov"
    log "Converting $input to ${output}.mov (CPU MPEG-2)..."

    ffmpeg -hide_banner \
        -loglevel "$log_level" \
        -stats \
        -i "$input" \
        -c:v mpeg2video \
        -q:v 1 \
        -maxrate "$bitrate" \
        -bufsize 20M \
        -c:a pcm_s16le \
        "${output}"

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
                err "Unknown option: $1"
                info "-hq : Medium Bandwidth (smaller files, good for 1080p editing)"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        err "Usage: ff-resolve-pro [-v] [-lb] input_file "
        return 1
    fi
    output="$(current_time)_${input%.*}.mov"
    log "Converting $input to ${output} for DaVinci Resolve..."
    info "Profile: $profile"

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
        "$output"

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
                err "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        err "Usage: ff-cpu [-v] input_file "
        return 1
    fi

    output="$(current_time)_${input%.*}.mp4"
    log "Encoding $input to ${output} (CPU x264)..."
    ffmpeg -hide_banner \
    -loglevel "$log_level" \
    -stats \
    -i "$input" \
    -c:v libx264 \
    -crf 20 \
    -preset slow \
    -c:a aac \
    -b:a 192k \
    "$output"
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
                err "Unknown option: $1"
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$input" ]]; then
        err "Usage: ff-mp3 [-v] input_file "
        return 1
    fi

    output="$(current_time)_${input%.*}.mp3"
    log "Extracting audio from $input to ${output}..."
    ffmpeg -hide_banner \
    -loglevel "$log_level" \
    -stats \
    -i "$input" \
    -vn \
    -c:a libmp3lame \
    -q:a 2 \
    "$output"
    local exit_status=$?
    alert "Audio Rip" "$output.mp3" "$exit_status"
}

gh-push(){
    local commit="$1"
    if [ -z "$commit" ]; then
        err "Usage: gh-push \"message\""
        return 1
    fi

    git add . &&  git commit -m "$commit" &&  git push
}

db-bak() {
    local service="$1"
    local timestamp=$(date +%Y%m%d_%H%M)
    local file="backup_${service}_${timestamp}.sql"

    if [[ -z "$service" ]]; then
        err "Error: Service name required."
        info "Usage: db-bak <service_name>"
        return 1
    fi

    if [[ -f "$file" ]]; then
        err "Error: Backup for this minute already exists ($file)."
        return 1
    fi

    log "Dumping $service to $file..."

    if pg_dump --clean --if-exists --no-owner --no-privileges "service=${service}" > "$file"; then
        log "Success: Created $file"
    else
        err "Dump failed. Cleaning up empty file..."
        rm -f "$file"
        return 1
    fi
}

db-restore() {
    local service="$1"
    local file="$2"

    if [[ -z "$service" || -z "$file" ]]; then
        err "Usage: db-restore <service_name> <backup_file.sql>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        err "Error: File '$file' not found."
        return 1
    fi

    warn "Warning: This will overwrite data in service: $service"
    info  "Continue? (y/n): "
    read -r confirmation
    if [[ "$confirmation" != "y" ]]; then
        err "Restore cancelled."
        return 0
    fi

    info "Restoring $file to $service..."

    if psql "service=${service}" < "$file"; then
        log "Success: $service has been restored from $file"
    else
        err "Error: Restore failed."
        return 1
    fi
}

au-test(){
    local duration="${1:-5}"
    local file_name="test_mic.wav"

    if [[ "$1" == "-p" ]]; then
        if [[ -f "$file_name" ]]; then
            aplay "$file_name"
            return 0
        else
            err "Error: No record found at $file_name"
            return 1
        fi
    fi

    if [[ ! "$duration" =~ ^[0-9]+$ ]]; then
        err "Error: '$duration' is not a valid number."
        info "Usage: au-test [duration_in_sec] or au-test -p"
        return 1
    fi

    arecord --format=cd --duration=${duration} ${file_name} && aplay ${file_name}
}


yt-download() {
    local url="$1"
    local upload_location="$HOME/Videos/YtDownloads/%(uploader)s - %(title)s.%(ext)s"

    if [[ -z "$url" ]]; then
        err "Usage: yt-download <url>"
        return 1
    fi

    mkdir -p "$HOME/Videos/YtDownloads"

    yt-dlp \
        -N 8 \
        --quiet --progress \
        --newline \
        --restrict-filenames \
        -o "$upload_location" \
        --exec 'echo -e "\n\033[0;32m{}"' \
        "$url"
}
pdf-comp(){
    local input="$1"
    local output="$2"

    if [[ -z "$input" ]]; then
        err "Usage: pdf-comp input_file"
        return 1
    fi

    output="$(current_time)_${input%.*}.pdf"

    gs -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.4 \
    -dPDFSETTINGS=/printer \
    -dNOPAUSE \
    -dQUIET \
    -dBATCH \
    -sOutputFile="$output" \
    "$input"
}

docx-comp() {
    local input="$1"
    local output="$(current_time)_${input%.*}.docx"

    if [[ -z "$input" ]]; then
        err "Usage: docx-comp input.docx "
        return 1
    fi

    local tmp_dir=$(mktemp -d)

    unzip -q "$input" -d "$tmp_dir"

    if [ -d "$tmp_dir/word/media" ]; then
        find "$tmp_dir/word/media" -type f -regex '.*\.\(jpg\|jpeg\|png\)' \
            -exec mogrify -resize 2000x2000\> -strip -quality 85 {} +
    fi

    (cd "$tmp_dir" && zip -rq - .) > "$output"

    rm -rf "$tmp_dir"

    log "Compressed docx saved as ${output}.docx"
}


ff-whisper-audio() {
    local log_level="error"
    local input=""
    local output=""

    while (( $# )); do
        case "$1" in
            -*)
                err "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$input" ]]; then
                    input="$1"
                else
                    output="$1"
                fi
                shift
                ;;
        esac
    done

    [[ -z "$input" || -z "$output" ]] && {
        err "Usage: ff-whisper-audio  input_file output.wav"
        return 1
    }

    ffmpeg -y -nostdin \
        -hide_banner \
        -loglevel "$log_level" \
        -stats \
        -i "$input" \
        -ar 16000 \
        -ac 1 \
        -c:a pcm_s16le \
        "$output"
}

whisper() {
    local input=""
    local model_alias="sm-en"
    local model=""
    local output=""

    while (( $# )); do
        case "$1" in
            -m|--model)
                if [[ -n "$2" && "$2" != -* ]];then
                    model_alias="$2"
                    shift 2
                else
                    err "Error: -m requires a model name."
                    return 1
                fi
                ;;
            -*)
                err "Unknown option: $1"
                info "Usage: whisper [-m model] <input_file>"
                return 1
                ;;
            *)
                input="$1"
                shift
                ;;
        esac
    done

    case "$model_alias" in
        sm-en)
            model="/usr/share/whisper.cpp-model-small.en/ggml-small.en.bin"
            ;;
        md-en)
            modal="/usr/share/whisper.cpp-model-medium.en/ggml-medium.en.bin"
            ;;
        *)
            info "Available models: * sm-en: small model (English)
                              * md-en: medium model (English)"
            return 1
            ;;
    esac

    if [[ -z "$input" ]]; then
        err "No input file provided"
        info "Usage: whisper [options] input.wav"
        return 1
    fi

    output="${input%.*}"
   case "$input" in
       *.mp4|*.mov|*.mkv)
           log "Detected video input → extracting & normalizing for Whisper"
           tmp1=$(make_tmp wav)
           trap 'rm -f "$tmp1"' EXIT

           ff-whisper-audio "$input" "$tmp1" || return 1
           input="$tmp1"
           ;;
       *.mp3|*.wav|*.m4a|*.ogg|*.opus)
           log "Detected audio input → normalizing for Whisper"
           tmp1=$(make_tmp wav)
           trap 'rm -f "$tmp1"' EXIT

           ff-whisper-audio "$input" "$tmp1" || return 1
           input="$tmp1"
           ;;
       *)
           err "Unsupported input format: $input"
           return 1
           ;;
   esac


    whisper-cli \
        -m "$model" \
        -f "$input" \
        -otxt \
        -of "$output"

    local exit_status=$?
    alert "Transcribe Finished" "$output.txt"  "$exit_status" "Whisper"
}


peek(){
    local dev="$1"

    if [[ -z "$dev" ]];then
        err "No device name provided"
        info "Usage: peek /dev/..."
        return 1
    fi

    if [[ ! -e "$dev" ]]; then
        err "Error: $dev not found."
        return 1
    fi

    sudo hexdump -C "$dev"


}


lsf (){
    local target="${1:-.}"
    # if [[ -z "$file" ]];then
    #     err "No file is Provided"
    #     info "Usage: foo file"
    #     return 1
    # fi

    find "$target" -maxdepth 1 -type f -exec lsd -l {} +
}
