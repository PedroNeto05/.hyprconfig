#!/bin/bash
#
# Bluetooth: habilita o bluetoothd e instala o vigia bt-a2dp-watchdog.
#
# Problema (BlueZ 5.87, Intel AX210 8087:0032, JBL Xtreme): quando a caixa
# reconecta sozinha ao mesmo tempo em que o PC inicia a conexão, a negociação
# A2DP fica sem resposta ("No reply to SetConfiguration request") e o bluetoothd
# não limpa esse estado. A partir daí toda conexão falha com
# br-connection-busy ("a2dp-sink profile connect failed ... Device or resource
# busy") até o daemon ser reiniciado. Trocar kernel/firmware não resolve: o
# controlador está saudável, quem trava é o bluetoothd.
#
# O vigia acompanha o log do bluetooth.service e reinicia o daemon quando vê
# esse travamento (no máximo uma vez por minuto). O reinício derruba as outras
# conexões Bluetooth ativas por alguns segundos.
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
# Reinicia o bluetoothd quando a negociação A2DP trava em br-connection-busy.
last=0
journalctl -u bluetooth.service -f -n0 -o cat | while IFS= read -r line; do
  case "$line" in
    *"No reply to SetConfiguration request"*|*"profile connect failed"*"Device or resource busy"*)
      now=$(date +%s)
      if (( now - last >= 60 )); then
        last=$now
        logger -t bt-a2dp-watchdog "A2DP travado: '$line' -> reiniciando bluetooth.service"
        sleep 3
        systemctl restart bluetooth.service
      fi
      ;;
  esac
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

  sudo systemctl daemon-reload
  sudo systemctl enable --now bt-a2dp-watchdog.service || true
}
