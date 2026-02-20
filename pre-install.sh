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

PACKAGES=(hypr rofi waybar keyboard themes git)

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

echo "🔹 Clonando repositório de dotfiles na home..."

DOTFILES_DIR="$HOME/.dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    echo "⚠️ Diretório ~/.dotfiles já existe. Pulando clone..."
else
    git clone https://github.com/PedroNeto05/.dotfiles.git "$DOTFILES_DIR"
fi

echo "🔹 Entrando no diretório dos dotfiles..."
cd "$DOTFILES_DIR" || { echo "❌ Falha ao entrar no diretório"; exit 1; }

if [ -f "stow.sh" ]; then
    echo "🔹 Executando stow.sh..."
    ./stow.sh
else
    echo "⚠️ stow.sh não encontrado!"
fi

echo "🔹 Alterando shell padrão para fish..."
if command -v fish &> /dev/null; then
    chsh -s /usr/bin/fish
else
    echo "⚠️ Fish não está instalado."
fi

echo "🔹 Instalando TPM (Tmux Plugin Manager)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
    echo "⚠️ TPM já está instalado. Pulando clone..."
else
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo "✅ Pre-install concluído!"
