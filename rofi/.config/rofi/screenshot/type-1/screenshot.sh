#!/usr/bin/env bash

dir="$HOME/.config/rofi/screenshot/type-1"
theme="style-1"

STATE_DIR="$HOME/.cache/screen-tool"
PID_FILE="$STATE_DIR/recording.pid"
VIDEO_FILE_STATE="$STATE_DIR/recording.file"

VIDEOS_DIR="$HOME/Videos/recordings"
IMAGES_DIR="$HOME/Pictures/screenshots"

# Garante que os diretórios necessários existam
mkdir -p "$STATE_DIR"
mkdir -p "$VIDEOS_DIR"
mkdir -p "$IMAGES_DIR"

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

  if [[ -f "$VIDEO_FILE_STATE" ]]; then
    video_file=$(cat "$VIDEO_FILE_STATE")
    echo -n "file://$video_file" | wl-copy -t text/uri-list
    rm -f "$VIDEO_FILE_STATE"
  fi
  exit 0
}

case "$choice" in
"Screenshot (Area)")
  sleep 0.5 # Dá tempo do Rofi fechar antes do slurp congelar a tela

  # Congela a tela usando o hyprpicker em background
  hyprpicker -r -z &
  picker_pid=$!
  sleep 0.1 # Garante que a tela congelou

  geometry=$(slurp)

  if [[ -n "$geometry" ]]; then
    # 1. Tira a foto ENQUANTO a tela ainda está congelada (salva na RAM em /tmp pra ser super rápido)
    temp_img="/tmp/screenshot-temp.png"
    grim -g "$geometry" "$temp_img"

    # 2. Descongela a tela matando o hyprpicker
    kill $picker_pid 2>/dev/null

    # 3. Abre a imagem limpa no swappy e depois exclui o arquivo temporário
    swappy -f "$temp_img"
    rm -f "$temp_img"
  else
    # Se o usuário apertar ESC no slurp, apenas descongela a tela
    kill $picker_pid 2>/dev/null
  fi
  ;;

"Screenshot (Full)")
  sleep 0.2
  grim - | swappy -f -
  ;;

"Record (Area)")
  sleep 0.5

  hyprpicker -r -z &
  picker_pid=$!
  sleep 0.1

  geometry=$(slurp)

  # Para vídeo, a ordem estava certa: solta a tela PRIMEIRO para o wf-recorder poder gravar o movimento
  kill $picker_pid 2>/dev/null

  if [[ -n "$geometry" ]]; then
    file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
    echo "$file" >"$VIDEO_FILE_STATE"

    wf-recorder -g "$geometry" -f "$file" >/dev/null 2>&1 &
    echo $! >"$PID_FILE"
  fi
  ;;

"Record (Full)")
  sleep 0.5

  file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
  echo "$file" >"$VIDEO_FILE_STATE"

  wf-recorder -f "$file" >/dev/null 2>&1 &
  echo $! >"$PID_FILE"
  ;;

"Stop Recording")
  stop_recording
  ;;
esac
