#!/usr/bin/env bash

dir="$HOME/.config/rofi/screenshot/type-1"
theme="style-1"

STATE_DIR="$HOME/.cache/screen-tool"
PID_FILE="$STATE_DIR/recording.pid"
VIDEO_FILE_STATE="$STATE_DIR/recording.file"

VIDEOS_DIR="$HOME/Videos/recordings"
IMAGES_DIR="$HOME/Pictures/screenshots"

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

  # Copia o arquivo do vídeo para o clipboard assim que a gravação encerra
  if [[ -f "$VIDEO_FILE_STATE" ]]; then
    video_file=$(cat "$VIDEO_FILE_STATE")
    # O echo -n evita quebra de linha, e o file:// avisa o sistema que é um arquivo
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
  sleep 0.1 # Garante que a tela congelou antes de chamar o slurp

  geometry=$(slurp)

  # Descongela a tela matando o processo
  kill $picker_pid 2>/dev/null

  # Executa a captura apenas se o usuário selecionou uma área (não apertou ESC)
  if [[ -n "$geometry" ]]; then
    mkdir -p "$IMAGES_DIR"
    file="$IMAGES_DIR/screenshot-$(date +%F-%T).png"
    grim -g "$geometry" "$file" >/dev/null 2>&1
    # Copia a imagem para o clipboard
    wl-copy -t image/png <"$file"
  fi
  ;;

"Screenshot (Full)")
  sleep 0.2 # Dá tempo do Rofi sumir da tela completamente
  mkdir -p "$IMAGES_DIR"
  file="$IMAGES_DIR/screenshot-$(date +%F-%T).png"
  grim "$file" >/dev/null 2>&1
  # Copia a imagem para o clipboard
  wl-copy -t image/png <"$file"
  ;;

"Record (Area)")
  sleep 0.5 # Evita que o Rofi apareça no congelamento da seleção

  # Congela a tela (útil para mirar exatamente onde o vídeo estava passando)
  hyprpicker -r -z &
  picker_pid=$!
  sleep 0.1

  geometry=$(slurp)

  # Solta a tela para o wf-recorder poder gravar o movimento
  kill $picker_pid 2>/dev/null

  if [[ -n "$geometry" ]]; then
    mkdir -p "$VIDEOS_DIR"
    file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
    # Salva o caminho temporariamente para o script lembrar qual arquivo copiar no final
    echo "$file" >"$VIDEO_FILE_STATE"

    wf-recorder -g "$geometry" -f "$file" >/dev/null 2>&1 &
    echo $! >"$PID_FILE"
  fi
  ;;

"Record (Full)")
  sleep 0.5 # Evita que o Rofi apareça nos primeiros frames do vídeo
  mkdir -p "$VIDEOS_DIR"
  file="$VIDEOS_DIR/record-$(date +%F-%T).mp4"
  # Salva o caminho temporariamente
  echo "$file" >"$VIDEO_FILE_STATE"

  wf-recorder -f "$file" >/dev/null 2>&1 &
  echo $! >"$PID_FILE"
  ;;

"Stop Recording")
  stop_recording
  ;;
esac
