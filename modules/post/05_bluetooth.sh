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
# O vigia acompanha o log do bluetooth.service e reinicia o daemon só quando
# uma conexão A2DP falha com "Device or resource busy" e o A2DP não sobe em 8 s
# (o EBUSY também aparece quando um pedido esbarra numa configuração em andamento).
# Ele NÃO reage ao "No reply to SetConfiguration request": logo depois disso a
# caixa costuma configurar o áudio sozinha, e reiniciar ali atrapalhava. Insiste
# se travar de novo (mínimo 5 s entre reinícios, máximo 4 em 10 min). O reinício
# derruba as outras conexões Bluetooth por alguns segundos. Limpar o cache de
# endpoints A2DP foi testado e não evita o travamento.
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
# Reinicia o bluetoothd quando a negociação A2DP fica presa em br-connection-busy.
# Insiste se a caixa travar outra vez logo após reconectar, com limite para não
# entrar em laço: mínimo de 5 s entre reinícios e no máximo 4 em 10 min.
MIN_GAP=5
WINDOW=600
MAX_IN_WINDOW=4
last=0
gave_up=0
history=()

journalctl -u bluetooth.service -f -n0 -o cat | while IFS= read -r line; do
  case "$line" in
    *"profile connect failed"*"Device or resource busy"*) ;;
    *) continue ;;
  esac
  now=$(date +%s)
  (( now - last < MIN_GAP )) && continue
  recent=()
  for t in "${history[@]}"; do (( now - t < WINDOW )) && recent+=("$t"); done
  history=("${recent[@]}")
  if (( ${#history[@]} >= MAX_IN_WINDOW )); then
    if (( now - gave_up >= WINDOW )); then
      gave_up=$now
      logger -t bt-a2dp-watchdog "A2DP continua travando (${#history[@]} reinícios em 10 min); pausando até a janela passar"
    fi
    continue
  fi
  # O EBUSY também aparece quando um segundo pedido esbarra numa configuração
  # que ainda está em andamento. Espera e só reinicia se o A2DP não subir
  # (transporte /org/bluez/.../dev_<MAC>/sepN/fdN ausente).
  mac=$(grep -oE '([0-9A-F]{2}:){5}[0-9A-F]{2}' <<<"$line" | head -n1)
  sleep 8
  if [ -n "$mac" ] && busctl tree --list org.bluez 2>/dev/null | grep -q "dev_${mac//:/_}/sep[0-9]*/fd"; then
    logger -t bt-a2dp-watchdog "EBUSY em $mac, mas o A2DP conectou; sem reiniciar"
    continue
  fi
  last=$(date +%s)
  history+=("$last")
  logger -t bt-a2dp-watchdog "A2DP travado: '$line' -> reiniciando bluetooth.service (${#history[@]}/$MAX_IN_WINDOW)"
  systemctl restart bluetooth.service
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
