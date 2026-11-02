#!/bin/bash

# Configura o Voxtype (ditado por voz local). A config fica no pacote stow
# 'voxtype' (~/.config/voxtype/config.toml), o atalho em keybinds.lua e o
# daemon sobe pelo autostart.lua (hl.on("hyprland.start")).
configure_voxtype() {
  if ! command -v voxtype &>/dev/null; then
    echo "Voxtype nao instalado. Pulando configuracao do ditado por voz..."
    return 0
  fi

  # O pacote voxtype-bin traz um binario Vulkan; 'setup gpu --enable' troca o
  # link /usr/bin/voxtype para ele (por isso o sudo). So vale se houver uma GPU
  # Vulkan de verdade - o llvmpipe (software) seria mais lento que a CPU.
  if command -v vulkaninfo &>/dev/null &&
    vulkaninfo --summary 2>/dev/null | grep -q 'deviceType.*\(DISCRETE\|INTEGRATED\)_GPU'; then
    echo "GPU Vulkan detectada: ativando aceleracao do Voxtype..."
    sudo voxtype setup gpu --enable || echo "Aviso: falha ao ativar a GPU no Voxtype."
  else
    echo "Sem GPU Vulkan: o Voxtype vai transcrever na CPU."
  fi

  echo "Baixando o modelo do Whisper definido em config.toml..."
  voxtype setup --download || echo "Aviso: falha ao baixar o modelo do Voxtype."
}
