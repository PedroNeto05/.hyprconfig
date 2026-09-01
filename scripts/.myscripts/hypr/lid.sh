#!/bin/bash
#
# Liga/desliga o painel interno do notebook ao abrir/fechar a TAMPA.
#
# Chamado pelos binds "switch:on/off:Lid Switch" em ~/.config/hypr/laptop.conf.
# Nao tem nada a ver com conectar monitor externo: plugar um externo mantem o
# painel interno ligado (a regra generica de monitor.conf liga tudo que aparece).
#
# Descobre o painel interno pelo nome (eDP-*, LVDS-*, DSI-*) em vez de assumir
# eDP-1, que varia entre maquinas.

set -u

# Nome do painel interno segundo o Hyprland, ex: "eDP-1".
internal_monitor() {
  hyprctl -j monitors all |
    grep -oE '"name": "(eDP|LVDS|DSI)-[0-9]+"' |
    head -n1 |
    cut -d'"' -f4
}

# Quantidade de monitores ativos que nao sao o painel interno.
external_count() {
  local internal="$1"
  hyprctl -j monitors |
    grep -oE '"name": "[^"]+"' |
    cut -d'"' -f4 |
    grep -vcx "$internal"
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
    hyprctl keyword monitor "${PANEL},disable"
  fi
  ;;
open)
  hyprctl keyword monitor "${PANEL},preferred,auto,1"
  ;;
*)
  echo "Uso: $0 {close|open}" >&2
  exit 1
  ;;
esac
