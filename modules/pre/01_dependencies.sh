#!/bin/bash

install_pre_dependencies() {
  echo "Atualizando sistema..."
  sudo pacman -Syu --noconfirm

  echo "Verificando dependencias essenciais..."
  local ESSENTIALS=(base-devel git wget curl unzip zip cmake stow openssh)
  local MISSING_PACKAGES=()

  for pkg in "${ESSENTIALS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
      MISSING_PACKAGES+=("$pkg")
    fi
  done

  if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
  fi

  echo "Verificando yay..."
  if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf /tmp/yay
  fi
}
