#!/bin/bash
#
# Liga/desliga o painel interno do notebook ao abrir/fechar a TAMPA.
#
# Chamado pelos binds "switch:on/off:Lid Switch" em ~/.config/hypr/laptop.lua.
# Nao tem nada a ver com conectar monitor externo: plugar um externo mantem o
# painel interno ligado (a regra generica de monitor.lua liga tudo que aparece).
#
# Descobre o painel interno pelo nome (eDP-*, LVDS-*, DSI-*) em vez de assumir
# eDP-1, que varia entre maquinas.

set -u

# Nomes dos monitores, um por linha. Usa a saida em TEXTO do hyprctl porque no
# JSON a chave "name" aparece tambem dentro de activeWorkspace/specialWorkspace,
# o que faria a contagem incluir nomes de workspace como se fossem monitores.
monitor_names() {
  hyprctl monitors "$@" | grep -oE '^Monitor [^ ]+' | awk '{print $2}'
}

# Nome do painel interno segundo o Hyprland, ex: "eDP-1".
internal_monitor() {
  monitor_names all | grep -m1 -E '^(eDP|LVDS|DSI)-[0-9]+$'
}

# Quantidade de monitores ATIVOS que nao sao o painel interno.
external_count() {
  local internal="$1"
  monitor_names | grep -vcx "$internal"
}

PANEL=$(internal_monitor)
[ -n "$PANEL" ] || exit 0

case "${1:-}" in
close)
  # Com monitor externo ligado, desligar o painel move as janelas para ele e a
  # sessao continua utilizavel. Sem externo, deixamos o logind suspender: apagar
  # o unico monitor deixaria o Hyprland sem saida de video.
  #
  # Caso de borda: se o externo for desconectado com a tampa ainda fechada, a
  # sessao fica sem saida de video ate a tampa ser aberta (o "open" abaixo
  # religa o painel).
  if [ "$(external_count "$PANEL")" -gt 0 ]; then
    hyprctl eval "hl.monitor({ output = \"${PANEL}\", disabled = true })"
  fi
  ;;
open)
  hyprctl eval "hl.monitor({ output = \"${PANEL}\", mode = \"preferred\", position = \"auto\", scale = 1 })"
  ;;
*)
  echo "Uso: $0 {close|open}" >&2
  exit 1
  ;;
esac
