#!/bin/bash
#
# Bluetooth: habilita o bluetoothd e instala o vigia bt-a2dp-watchdog.
#
# Problema (BlueZ 5.87, Intel AX210 8087:0032, JBL Xtreme), visto com btmon:
# quando o PC inicia o A2DP, a caixa costuma fechar o canal AVDTP ~10 ms depois
# do SetConfiguration ("No reply to SetConfiguration request" no log) e tenta
# configurar o áudio ela mesma. Às vezes consegue; quando não, o bluetoothd não
# limpa o estado e toda conexão falha com br-connection-busy ("a2dp-sink profile
# connect failed ... Device or resource busy") até o daemon ser reiniciado.
# Trocar kernel/firmware não resolve: quem trava é o bluetoothd.
#
# A caixa também procura o serviço HFP AG ao ligar e desconecta se não achar;
# o HFP AG é ligado no WirePlumber (stow package wireplumber/) e aqui é removido
# o antigo /etc/wireplumber/.../51-disable-bluez-hfp.conf que o desligava.
#
# O vigia olha o estado, não o log: a cada 5 s, para cada caixa/fone conectado,
# se o A2DP falta há 15 s ele pede o A2DP (ConnectProfile); se o pedido falha
# (bluetoothd travado) ele reinicia o bluetooth.service (mínimo 30 s entre
# reinícios, máximo 4 em 10 min); e quando o A2DP volta ele troca o perfil do
# WirePlumber de viva-voz para a2dp-sink (o WirePlumber fica no viva-voz se o
# HFP chegou antes). Ler o log não bastava: na volta de uma suspensão o A2DP
# travou sem ninguém tentar de novo, então nenhum erro apareceu. Ele também não
# reage ao "No reply to SetConfiguration request", porque logo depois disso a
# caixa costuma configurar o áudio sozinha. O reinício derruba as outras
# conexões Bluetooth por alguns segundos. Limpar o cache de endpoints A2DP foi
# testado e não evita o travamento.
#
# Pode ser rodado isolado:
#   bash -c 'source modules/post/05_bluetooth.sh && configure_bluetooth'

configure_bluetooth() {
  if ! pacman -Qq bluez &>/dev/null; then
    echo "BlueZ não instalado: pulando configuração do Bluetooth."
    return
  fi

  echo "Habilitando o serviço do Bluetooth..."
  sudo systemctl enable --now bluetooth.service || true

  echo "Instalando o vigia do A2DP (bt-a2dp-watchdog)..."
  sudo tee /usr/local/bin/bt-a2dp-watchdog >/dev/null <<'EOF'
#!/bin/bash
# Gerado por modules/post/05_bluetooth.sh (dotfiles).
# Garante o A2DP de caixas e fones conectados. A cada POLL segundos, para cada
# aparelho de áudio conectado (Icon audio-* com o serviço "Audio Sink"):
#  - sem transporte A2DP há GRACE segundos -> pede o A2DP (ConnectProfile);
#  - se o pedido falhar (ex.: br-connection-busy, bluetoothd travado) ->
#    reinicia o bluetooth.service (mínimo MIN_GAP s entre reinícios e no
#    máximo MAX_IN_WINDOW reinícios em WINDOW s, para não entrar em laço);
#  - quando o A2DP aparece depois de ter faltado -> troca o perfil do
#    WirePlumber de viva-voz para a2dp-sink (ele fica no viva-voz quando o HFP
#    chega antes do A2DP).
A2DP_SINK=0000110b-0000-1000-8000-00805f9b34fb
POLL=5
GRACE=15
MIN_GAP=30
WINDOW=600
MAX_IN_WINDOW=4

declare -A missing_since
history=()
last=0
gave_up=0

log() { logger -t bt-a2dp-watchdog "$*"; }

device_path() {
  busctl tree --list org.bluez 2>/dev/null | grep -m1 "/dev_${1//:/_}\$"
}

has_transport() {
  busctl tree --list org.bluez 2>/dev/null | grep -q "/dev_${1//:/_}/sep[0-9]*/fd"
}

is_audio_sink() {
  local info
  info=$(timeout 5 bluetoothctl info "$1" 2>/dev/null)
  grep -q 'Icon: audio-' <<<"$info" && grep -q 'UUID: Audio Sink' <<<"$info"
}

# Roda o pactl na sessão de cada usuário com PipeWire/Pulse ativo.
set_a2dp_profile() {
  local card="bluez_card.${1//:/_}" dir uid user
  for dir in /run/user/*; do
    [ -S "$dir/pulse/native" ] || continue
    uid=${dir##*/}
    user=$(id -nu "$uid" 2>/dev/null) || continue
    if runuser -u "$user" -- env XDG_RUNTIME_DIR="$dir" pactl list cards 2>/dev/null |
      grep -A80 "Name: $card\$" | grep -m1 'Active Profile:' | grep -q 'headset'; then
      runuser -u "$user" -- env XDG_RUNTIME_DIR="$dir" \
        pactl set-card-profile "$card" a2dp-sink &&
        log "$1: A2DP voltou; perfil trocado do viva-voz para a2dp-sink"
    fi
  done
}

restart_bt() {
  local now recent=() t
  now=$(date +%s)
  (( now - last < MIN_GAP )) && return 1
  for t in "${history[@]}"; do (( now - t < WINDOW )) && recent+=("$t"); done
  history=("${recent[@]}")
  if (( ${#history[@]} >= MAX_IN_WINDOW )); then
    if (( now - gave_up >= WINDOW )); then
      gave_up=$now
      log "A2DP continua falhando (${#history[@]} reinícios em 10 min); pausando até a janela passar"
    fi
    return 1
  fi
  last=$now
  history+=("$now")
  log "$1 -> reiniciando bluetooth.service (${#history[@]}/$MAX_IN_WINDOW)"
  systemctl restart bluetooth.service
}

while sleep "$POLL"; do
  now=$(date +%s)
  connected=$(timeout 5 bluetoothctl devices Connected 2>/dev/null | awk '$1 == "Device" {print $2}')

  for mac in "${!missing_since[@]}"; do
    grep -qx "$mac" <<<"$connected" || unset "missing_since[$mac]"
  done

  for mac in $connected; do
    is_audio_sink "$mac" || continue

    if has_transport "$mac"; then
      if [ -n "${missing_since[$mac]:-}" ]; then
        unset "missing_since[$mac]"
        sleep 1
        set_a2dp_profile "$mac"
      fi
      continue
    fi

    if [ -z "${missing_since[$mac]:-}" ]; then
      missing_since[$mac]=$now
      continue
    fi
    (( now - missing_since[$mac] < GRACE )) && continue

    path=$(device_path "$mac")
    [ -n "$path" ] || continue
    if out=$(timeout 20 busctl call org.bluez "$path" org.bluez.Device1 \
      ConnectProfile s "$A2DP_SINK" 2>&1); then
      log "$mac: conectado sem A2DP há $((now - missing_since[$mac])) s; A2DP pedido com sucesso"
      missing_since[$mac]=$now
    else
      if restart_bt "$mac: conectado sem A2DP e o pedido falhou (${out//$'\n'/ })"; then
        missing_since=()
      else
        missing_since[$mac]=$now
      fi
    fi
  done
done
EOF
  sudo chmod 755 /usr/local/bin/bt-a2dp-watchdog

  sudo tee /etc/systemd/system/bt-a2dp-watchdog.service >/dev/null <<'EOF'
# Gerado por modules/post/05_bluetooth.sh (dotfiles).
[Unit]
Description=Reinicia bluetoothd quando o A2DP fica preso em br-connection-busy
After=bluetooth.service
Wants=bluetooth.service

[Service]
ExecStart=/usr/local/bin/bt-a2dp-watchdog
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  # Tentativa antiga de correção (recarregar o btusb no boot): não resolve o
  # travamento do bluetoothd e recarregar o driver do AX210 é arriscado.
  if [ -f /etc/systemd/system/reload-btusb.service ]; then
    echo "Removendo o reload-btusb.service obsoleto..."
    sudo systemctl disable reload-btusb.service || true
    sudo rm -f /etc/systemd/system/reload-btusb.service
  fi

  # Config antiga que desligava o HFP: a JBL precisa do HFP AG para reconectar.
  if [ -f /etc/wireplumber/wireplumber.conf.d/51-disable-bluez-hfp.conf ]; then
    echo "Removendo a config antiga que desligava o HFP no WirePlumber..."
    sudo rm -f /etc/wireplumber/wireplumber.conf.d/51-disable-bluez-hfp.conf
  fi

  sudo systemctl daemon-reload
  sudo systemctl enable bt-a2dp-watchdog.service || true
  # restart (não só --now) para um vigia já rodando carregar o script novo
  sudo systemctl restart bt-a2dp-watchdog.service || true
}
