#!/usr/bin/env bash

dir="$HOME/.config/rofi/screenshot/type-1"
theme="style-1"

STATE_DIR="$HOME/.cache/screen-tool"
PID_FILE="$STATE_DIR/recording.pid"

VIDEOS_DIR="$HOME/Videos/recordings"
IMAGES_DIR="$HOME/Images/screenshots"

mkdir -p "$STATE_DIR"

IS_RECORDING=false
[[ -f "$PID_FILE" ]] && IS_RECORDING=true

record_area_label=$([[ $IS_RECORDING == true ]] && echo "Stop Recording" || echo "Record (Area)")
record_full_label=$([[ $IS_RECORDING == true ]] && echo "Stop Recording" || echo "Record (Full)")

record_icon=$([[ $IS_RECORDING == true ]] && echo "media-playback-stop" || echo "media-record")

menu=$(
cat <<EOF
Screenshot (Area)\0icon\x1fcamera-photo
Screenshot (Full)\0icon\x1fcamera-photo
$record_area_label\0icon\x1f$record_icon
$record_full_label\0icon\x1f$record_icon
EOF
)

choice=$(echo -e "$menu" | rofi -dmenu -markup-rows -i -theme "$dir/$theme")
[[ -z "$choice" ]] && exit 0

stop_recording() {
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    exit 0
}

case "$choice" in
    "Screenshot (Area)")
        mkdir -p "$IMAGES_DIR"
        grim -g "$(slurp)" \
            "$IMAGES_DIR/screenshot-$(date +%F-%T).png" \
            >/dev/null 2>&1
        ;;

    "Screenshot (Full)")
        mkdir -p "$IMAGES_DIR"
        grim \
            "$IMAGES_DIR/screenshot-$(date +%F-%T).png" \
            >/dev/null 2>&1
        ;;

    "Record (Area)")
        mkdir -p "$VIDEOS_DIR"
        geometry=$(slurp)
        wf-recorder -g "$geometry" \
            -f "$VIDEOS_DIR/record-$(date +%F-%T).mp4" \
            >/dev/null 2>&1 &
        echo $! > "$PID_FILE"
        ;;

    "Record (Full)")
        mkdir -p "$VIDEOS_DIR"
        wf-recorder \
            -f "$VIDEOS_DIR/record-$(date +%F-%T).mp4" \
            >/dev/null 2>&1 &
        echo $! > "$PID_FILE"
        ;;

    "Stop Recording")
        stop_recording
        ;;
esac
