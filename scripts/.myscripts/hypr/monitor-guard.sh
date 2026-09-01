#!/bin/bash
#
# Suspende o notebook quando o ultimo monitor externo e desconectado enquanto a
# tampa ja esta fechada.
#
# O cenario: com a tampa fechada e um monitor externo ligado, o lid.sh desliga o
# painel interno e o logind nao suspende (HandleLidSwitchDocked=ignore, ver
# modules/post/03_laptop.sh). Se o cabo do monitor for arrancado nesse estado, o
# logind NAO reavalia o "docked" -- ele so olha isso no instante do evento de
# tampa -- entao a maquina ficaria acordada e sem saida de video dentro da
# mochila. Este daemon fecha essa lacuna reagindo ao hotplug do monitor.
#
# Roda como exec-once do Hyprland (ver autostart.conf), nao como unit systemd:
# depende de HYPRLAND_INSTANCE_SIGNATURE e deve morrer junto com a sessao.
# Em desktop sai na hora, por nao existir painel interno.

set -u

DEBOUNCE=2 # segundos de espera antes de olhar o estado, para o Hyprland assentar

# Nomes dos monitores, um por linha. Igual ao lid.sh: usa a saida em TEXTO
# porque no JSON a chave "name" aparece tambem em activeWorkspace/
# specialWorkspace e a contagem sairia errada.
monitor_names() {
  hyprctl monitors "$@" | grep -oE '^Monitor [^ ]+' | awk '{print $2}'
}

internal_monitor() {
  monitor_names all | grep -m1 -E '^(eDP|LVDS|DSI)-[0-9]+$'
}

# 0 se a tampa esta fechada. Quando o kernel nao expoe /proc/acpi/button/lid
# (comum), cai na heuristica: o painel interno existe mas nao esta ativo, o que
# so acontece depois do lid.sh o ter desligado.
lid_closed() {
  local state
  for state in /proc/acpi/button/lid/*/state; do
    [ -r "$state" ] || continue
    grep -q closed "$state" && return 0
    return 1
  done

  ! monitor_names | grep -qx "$PANEL"
}

# Ha alguma saida de video real ligada? Ignora monitores virtuais/headless que o
# Hyprland cria como fallback quando fica sem nenhuma saida fisica.
has_real_output() {
  monitor_names | grep -qE '^(eDP|LVDS|DSI|HDMI-A|HDMI|DP|DVI|VGA)'
}

# Caminho do socket de eventos da instancia atual do Hyprland.
event_socket() {
  echo "${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
}

PANEL=$(internal_monitor)
if [ -z "$PANEL" ]; then
  # Sem painel interno = desktop. Nada a vigiar.
  exit 0
fi

command -v socat >/dev/null 2>&1 || {
  notify-send -a "Monitor" -u critical \
    "monitor-guard desativado" "O pacote socat nao esta instalado." 2>/dev/null
  exit 1
}

# Reconecta caso o socat caia (ex: Hyprland reiniciado).
while true; do
  SOCKET=$(event_socket)

  if [ ! -S "$SOCKET" ]; then
    sleep 5
    continue
  fi

  socat -U - "UNIX-CONNECT:$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
    monitorremoved*) ;;
    *) continue ;;
    esac

    sleep "$DEBOUNCE"

    # Suspende so quando as duas coisas valem: nao sobrou saida de video E a
    # tampa esta fechada. Com a tampa aberta, ficar sem monitor e problema do
    # usuario -- ele ainda pode reconectar o cabo.
    if ! has_real_output && lid_closed; then
      logger -t monitor-guard "ultimo monitor removido com a tampa fechada; suspendendo"
      systemctl suspend
    fi
  done

  sleep 5
done
