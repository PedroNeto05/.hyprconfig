#!/bin/bash
#
# Configuracao especifica de notebook. So roda quando IS_LAPTOP=true
# (definido por collect_laptop_packages em modules/install/00_hardware.sh).
#
# Cobre: perfis de energia, controle termico, GPU hibrida, comportamento da
# tampa (lid switch) e acao de bateria critica.

configure_laptop() {
  if [ "$IS_LAPTOP" != true ]; then
    echo "Chassi desktop: pulando configuracao de notebook."
    return
  fi

  echo "Configurando ambiente de notebook..."

  # --- Perfis de energia -----------------------------------------------------
  # O power-profiles-daemon expoe os perfis power-saver/balanced/performance
  # via D-Bus; e o que o modulo da waybar e o powerprofilesctl consomem.
  if pacman -Qq power-profiles-daemon &>/dev/null; then
    echo "Habilitando power-profiles-daemon..."
    sudo systemctl enable --now power-profiles-daemon.service || true
  fi

  # --- Controle termico (Intel) ---------------------------------------------
  if pacman -Qq thermald &>/dev/null; then
    echo "Habilitando thermald (gerenciamento termico Intel)..."
    sudo systemctl enable --now thermald.service || true
  fi

  # --- GPU hibrida -----------------------------------------------------------
  if pacman -Qq switcheroo-control &>/dev/null; then
    echo "Habilitando switcheroo-control (GPU hibrida)..."
    sudo systemctl enable --now switcheroo-control.service || true
  fi

  # --- Sensores (rotacao de tela / luz ambiente) -----------------------------
  if pacman -Qq iio-sensor-proxy &>/dev/null; then
    echo "Habilitando iio-sensor-proxy (acelerometro / sensor de luz)..."
    sudo systemctl enable --now iio-sensor-proxy.service || true
  fi

  # --- Comportamento da tampa ------------------------------------------------
  # Na bateria: suspende. Na tomada: apenas bloqueia (permite deixar download ou
  # compilacao rodando de tampa fechada). Com monitor externo ligado o Hyprland
  # cuida de desligar so o painel interno ao fechar a tampa (ver
  # hypr/laptop.lua), por isso "docked" fica em ignore aqui.
  echo "Configurando acao da tampa (systemd-logind)..."
  sudo mkdir -p /etc/systemd/logind.conf.d
  sudo tee /etc/systemd/logind.conf.d/90-laptop-lid.conf >/dev/null <<'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=lock
HandleLidSwitchDocked=ignore
EOF

  # --- Bateria critica -------------------------------------------------------
  # Desliga a maquina em 3% em vez de deixar o kernel morrer sem sincronizar.
  # Troque para HybridSleep se voce tiver swap >= RAM configurado para hibernar.
  if pacman -Qq upower &>/dev/null; then
    echo "Configurando acao de bateria critica (UPower)..."
    sudo mkdir -p /etc/UPower
    if [ -f /etc/UPower/UPower.conf ]; then
      sudo sed -i \
        -e 's/^#\?PercentageLow=.*/PercentageLow=20/' \
        -e 's/^#\?PercentageCritical=.*/PercentageCritical=8/' \
        -e 's/^#\?PercentageAction=.*/PercentageAction=3/' \
        -e 's/^#\?CriticalPowerAction=.*/CriticalPowerAction=PowerOff/' \
        /etc/UPower/UPower.conf
      sudo systemctl restart upower.service || true
    fi
  fi

  echo "Configuracao de notebook concluida."
}
