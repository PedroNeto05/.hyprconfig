#!/usr/bin/env bash

dir="$HOME/.config/rofi/screenshot/type-1"
theme="style-1"

STATE_DIR="$HOME/.cache/screen-tool"
PID_FILE="$STATE_DIR/recording.pid"
VIDEO_FILE_STATE="$STATE_DIR/recording.file"

VIDEOS_DIR="$HOME/Videos/recordings"
IMAGES_DIR="$HOME/Pictures/screenshots"

# Garante que os diretórios existam
mkdir -p "$STATE_DIR"
mkdir -p "$VIDEOS_DIR"
mkdir -p "$IMAGES_DIR"

IS_RECORDING=false
[[ -f "$PID_FILE" ]] && IS_RECORDING=true

stop_recording() {
  kill "$(cat "$PID_FILE")" 2>/dev/null
  rm -f "$PID_FILE"

  if [[ -f "$VIDEO_FILE_STATE" ]]; then
    video_file=$(cat "$VIDEO_FILE_STATE")
    echo -n "file://$video_file" | wl-copy -t text/uri-list
    rm -f "$VIDEO_FILE_STATE"
  fi
  exit 0
}

# Abre o swappy e decide o que vai para o clipboard depois que ele fechar
edit_and_copy() {
  local final_file="$1"
  local edited_tmp="/tmp/swappy-edited.png"
  rm -f "$edited_tmp" # Limpa resquícios de edições anteriores

  swappy -f "$final_file" -o "$edited_tmp"

  if [[ -f "$edited_tmp" ]]; then
    # O usuário salvou uma edição: copia a editada e substitui a original
    wl-copy -t image/png <"$edited_tmp"
    mv "$edited_tmp" "$final_file"
  else
    # O usuário apenas fechou o swappy: copia a imagem original
    wl-copy -t image/png <"$final_file"
  fi
}

screenshot_area() {
  sleep "${1:-0.5}" # Dá tempo do Rofi fechar

  # Congela a tela
  hyprpicker -r -z &
  local picker_pid=$!
  sleep 0.1

  local geometry
  geometry=$(slurp)

  if [[ -n "$geometry" ]]; then
    local final_file="$IMAGES_DIR/screenshot-$(date +%F-%T).png"

    # 1. Tira a foto original e salva no HD (enquanto a tela tá congelada)
    grim -g "$geometry" "$final_file"

    # 2. Descongela a tela matando o hyprpicker
    kill $picker_pid 2>/dev/null

    # 3. Edita no swappy e resolve o clipboard
    edit_and_copy "$final_file"
  else
    # Cancelou no slurp com ESC
    kill $picker_pid 2>/dev/null
  fi
}

screenshot_full() {
  sleep 0.2
  local final_file="$IMAGES_DIR/screenshot-$(date +%F-%T).png"

  # Tira a foto inteira e salva no HD
  grim "$final_file"

  edit_and_copy "$final_file"
}

record_area() {
  sleep "${1:-0.5}"

  hyprpicker -r -z &
  local picker_pid=$!
  sleep 0.1

  local geometry
  geometry=$(slurp)
  kill $picker_pid 2>/dev/null

  if [[ -n "$geometry" ]]; then
    local file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
    echo "$file" >"$VIDEO_FILE_STATE"

    wf-recorder -g "$geometry" -f "$file" >/dev/null 2>&1 &
    echo $! >"$PID_FILE"
  fi
}

record_full() {
  sleep "${1:-0.5}"

  local file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
  echo "$file" >"$VIDEO_FILE_STATE"

  wf-recorder -f "$file" >/dev/null 2>&1 &
  echo $! >"$PID_FILE"
}

# Modo direto: permite chamar uma ação sem passar pelo menu do Rofi
case "$1" in
area)
  screenshot_area 0.1
  exit 0
  ;;
full)
  screenshot_full
  exit 0
  ;;
record-area)
  [[ $IS_RECORDING == true ]] && stop_recording
  record_area 0.1
  exit 0
  ;;
record-full)
  [[ $IS_RECORDING == true ]] && stop_recording
  record_full 0.1
  exit 0
  ;;
stop)
  [[ $IS_RECORDING == true ]] && stop_recording
  exit 0
  ;;
esac

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

case "$choice" in
"Screenshot (Area)")
  screenshot_area
  ;;

"Screenshot (Full)")
  screenshot_full
  ;;

"Record (Area)")
  record_area
  ;;

"Record (Full)")
  record_full
  ;;

"Stop Recording")
  stop_recording
  ;;
esac
