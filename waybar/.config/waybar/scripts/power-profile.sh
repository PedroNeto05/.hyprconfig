#!/bin/bash
#
# Widget de perfil de energia para a waybar (power-profiles-daemon).
#
#   status  -> imprime JSON para o modulo custom/power-profile
#   next    -> alterna para o proximo perfil disponivel e notifica
#
# Os perfis disponiveis variam por maquina: quase todo notebook expoe
# power-saver e balanced; performance so aparece onde a plataforma suporta.

set -u

command -v powerprofilesctl >/dev/null 2>&1 || {
  [ "${1:-status}" = "status" ] && echo '{"text": "", "tooltip": "power-profiles-daemon nao instalado"}'
  exit 0
}

icon_for() {
  case "$1" in
  power-saver) echo "󰌪" ;;
  balanced) echo "󰾅" ;;
  performance) echo "󰓅" ;;
  *) echo "󰈐" ;;
  esac
}

label_for() {
  case "$1" in
  power-saver) echo "Economia" ;;
  balanced) echo "Equilibrado" ;;
  performance) echo "Desempenho" ;;
  *) echo "$1" ;;
  esac
}

CURRENT=$(powerprofilesctl get 2>/dev/null)

case "${1:-status}" in
status)
  echo "{\"text\": \"$(icon_for "$CURRENT")\", \"tooltip\": \"Perfil de energia: $(label_for "$CURRENT")\", \"class\": \"$CURRENT\"}"
  ;;
next)
  # "powerprofilesctl list" marca o perfil ativo com "*"; aqui so precisamos dos
  # nomes, na ordem em que o daemon os expoe.
  mapfile -t PROFILES < <(powerprofilesctl list 2>/dev/null |
    grep -oE '^[* ] [a-z-]+:' | tr -d '*: ')

  [ "${#PROFILES[@]}" -gt 0 ] || exit 0

  NEXT="${PROFILES[0]}"
  for i in "${!PROFILES[@]}"; do
    if [ "${PROFILES[$i]}" = "$CURRENT" ]; then
      NEXT="${PROFILES[$(((i + 1) % ${#PROFILES[@]}))]}"
      break
    fi
  done

  powerprofilesctl set "$NEXT"
  command -v notify-send >/dev/null 2>&1 &&
    notify-send -a "Energia" -i battery -t 2000 "Perfil de energia" "$(label_for "$NEXT")"
  ;;
*)
  echo "Uso: $0 {status|next}" >&2
  exit 1
  ;;
esac
