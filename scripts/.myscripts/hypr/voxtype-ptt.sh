#!/bin/sh
#
# Push-to-talk do voxtype chamado pelos binds do Hyprland (ver keybinds.lua).
#
# O problema que isto resolve: o `bindr = SUPER, D` so dispara se o Super ainda
# estiver apertado quando o D sobe. Soltando o Super antes do D, a gravacao
# ficava presa. Por isso soltar o proprio Super tambem chama `stop`.
#
# Soltar o Super acontece o tempo todo (qualquer atalho), e nao pode parar uma
# gravacao iniciada pelo toggle (Super+Shift+D). Entao `start` deixa uma marca e
# `stop` so age se ela existir -- sem a marca sai na hora, sem chamar o voxtype.
#
# `voxtype record stop` com o daemon ocioso nao faz nada, entao nao e preciso
# consultar o estado (o que abriria uma corrida num toque rapido em Super+D).

FLAG="${XDG_RUNTIME_DIR:-/tmp}/voxtype-ptt"

case "$1" in
start)
  : >"$FLAG"
  exec voxtype record start
  ;;
stop)
  [ -e "$FLAG" ] || exit 0
  rm -f "$FLAG"
  exec voxtype record stop
  ;;
toggle)
  rm -f "$FLAG"
  exec voxtype record toggle
  ;;
*)
  echo "uso: $0 start|stop|toggle" >&2
  exit 1
  ;;
esac
