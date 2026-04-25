#!/bin/bash

setup_pre_environment() {
  echo "Aplicando dotfiles com Stow (Modular)..."
  cd "$DOTFILES_DIR"

  local PACKAGES=(hypr rofi waybar keyboard themes git vesktop dunst nautilus-scripts systemd-daemons scripts swappy zathura)

  for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
      echo "Linkando: $pkg"
      stow -R "$pkg" -t "$HOME"
    fi
  done

  echo "Instalando fontes do Rofi..."
  mkdir -p "$HOME/.local/share/fonts"

  local IFONTES="$DOTFILES_DIR/rofi/.config/rofi/fonts"
  if [ -d "$IFONTES" ]; then
    cp -rf "$IFONTES/"* "$HOME/.local/share/fonts/"
    echo "Fontes copiadas para $HOME/.local/share/fonts"
  fi

  fc-cache -fv >/dev/null

  echo "Clonando repositorio de dotfiles na home..."
  local CLONE_DIR="$HOME/.dotfiles"

  if [ -d "$CLONE_DIR" ]; then
    echo "Diretorio ~/.dotfiles ja existe. Pulando clone..."
  else
    git clone https://github.com/PedroNeto05/.dotfiles.git "$CLONE_DIR"
  fi

  echo "Entrando no repositorio e executando stow.sh..."
  cd "$CLONE_DIR" || {
    echo "Falha ao entrar no diretorio dos dotfiles"
    exit 1
  }

  if [ -f "./stow.sh" ]; then
    bash ./stow.sh
  else
    echo "Aviso: stow.sh nao encontrado em $CLONE_DIR"
  fi

  local BTRFS_SCRIPT="$SCRIPT_DIR/modules/pre/03_btrfs.sh"

  if command -v snapper &>/dev/null; then
    echo "Snapper detectado no sistema."
    if [ -f "$BTRFS_SCRIPT" ]; then
      echo "Executando $BTRFS_SCRIPT..."
      sudo bash "$BTRFS_SCRIPT"
    else
      echo "$BTRFS_SCRIPT nao encontrado."
    fi
  else
    echo "Snapper nao instalado. Pulando configuracao BTRFS."
  fi

  echo "Instalando TPM (Tmux Plugin Manager)..."
  local TPM_DIR="$HOME/.tmux/plugins/tpm"

  if [ -d "$TPM_DIR" ]; then
    echo "TPM ja esta instalado. Pulando clone..."
  else
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi

  echo "Pre-install concluido!"
}
