#!/bin/bash

set -e

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

echo "🔹 Atualizando sistema..."
sudo pacman -Syu --noconfirm

echo "🔹 Verificando dependências essenciais..."
ESSENTIALS=(base-devel git wget curl unzip zip cmake stow openssh)

MISSING_PACKAGES=()
for pkg in "${ESSENTIALS[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    sudo pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
fi

echo "🔹 Verificando yay..."
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf /tmp/yay
fi

echo "✅ Aplicando dotfiles com Stow (Modular)..."
cd "$DOTFILES_DIR"

PACKAGES=(hypr rofi waybar keyboard themes)

for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo "→ Linkando: $pkg"
        stow -R "$pkg" -t "$HOME"
    fi
done

echo "🔹 Instalando fontes do Rofi..."
mkdir -p "$HOME/.local/share/fonts"

# Ajustado para a nova estrutura: rofi/.config/rofi/fonts
IFONTES="$DOTFILES_DIR/rofi/.config/rofi/fonts"
if [ -d "$IFONTES" ]; then
    cp -rf "$IFONTES/"* "$HOME/.local/share/fonts/"
    echo "✔ Fontes copiadas para $HOME/.local/share/fonts"
fi

fc-cache -fv > /dev/null

echo "✅ Pre-install concluído!"
