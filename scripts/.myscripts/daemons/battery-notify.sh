#!/bin/bash
#
# Avisa quando a bateria fica fraca. Sem um ambiente de desktop completo nada
# faz isso no Hyprland: a waybar so muda de cor, o que passa despercebido.
#
# Roda como daemon (loop) via battery-notify.service. A acao de desligamento em
# nivel critico e do UPower (ver modules/post/03_laptop.sh); aqui so avisamos.

set -u

INTERVALO=60 # segundos entre verificacoes
AVISO=20     # % - notificacao normal
CRITICO=10   # % - notificacao urgente

BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
[ -n "$BAT" ] || exit 0 # desktop: nada a fazer

# Guarda o ultimo limiar disparado para nao repetir a notificacao a cada minuto.
# Zera quando o carregador e conectado ou quando a carga sobe de novo.
ultimo_aviso=""

while true; do
  capacidade=$(cat "$BAT/capacity" 2>/dev/null)
  estado=$(cat "$BAT/status" 2>/dev/null)

  if [ -z "$capacidade" ]; then
    sleep "$INTERVALO"
    continue
  fi

  if [ "$estado" = "Discharging" ]; then
    if [ "$capacidade" -le "$CRITICO" ] && [ "$ultimo_aviso" != "critico" ]; then
      notify-send -a "Bateria" -u critical -i battery-caution \
        "Bateria critica: ${capacidade}%" \
        "Conecte o carregador. O sistema sera desligado automaticamente em 3%."
      ultimo_aviso="critico"
    elif [ "$capacidade" -le "$AVISO" ] && [ "$capacidade" -gt "$CRITICO" ] &&
      [ "$ultimo_aviso" != "aviso" ]; then
      notify-send -a "Bateria" -u normal -i battery-low \
        "Bateria fraca: ${capacidade}%" \
        "Considere conectar o carregador."
      ultimo_aviso="aviso"
    fi
  else
    ultimo_aviso=""
  fi

  sleep "$INTERVALO"
done
