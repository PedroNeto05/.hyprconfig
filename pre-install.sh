#!/bin/bash

set -e

# Descobre o diretório onde o script está localizado
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

# Lista de pastas que você quer "stowar"
# Removi 'scripts' e 'wallpapers' da lista caso você não queira que eles 
# criem links na sua $HOME (geralmente eles ficam dentro do repo)
PACKAGES=(hypr rofi waybar)

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
