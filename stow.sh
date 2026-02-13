#!/bin/bash

set -e

# Pacotes
HOME_PKGS=("hyprland" "rofi" "waybar")
ROOT_PKGS=("sddm")
REFIND_PKG="refind"
PLYMOUTH_PKG="plymouth"

STOW="stow"
STOW_FLAGS="--verbose"

echo "🔹 Instalando pacotes na HOME"

for dir in "${HOME_PKGS[@]}"; do
    echo "→ stow $dir (HOME)"
    $STOW $STOW_FLAGS --target="$HOME" "$dir"
done

echo ""
echo "🔹 Instalando pacotes no ROOT (sudo necessário)"

for dir in "${ROOT_PKGS[@]}"; do
    echo "→ stow $dir (/)"
    sudo $STOW $STOW_FLAGS --target=/ "$dir"
done

echo ""
echo "🔹 Instalando configs do rEFInd"
echo "→ Criando backup se existir"

sudo mv -n /boot/EFI/refind/refind.conf /boot/EFI/refind/refind.conf.bak 2>/dev/null || true
sudo mv -n /boot/refind_linux.conf /boot/refind_linux.conf.bak 2>/dev/null || true

echo "→ stow $REFIND_PKG (/)"
sudo $STOW $STOW_FLAGS --target=/ "$REFIND_PKG"

echo ""
echo "🔹 Instalando configs do Plymouth"
echo "→ Backup do mkinitcpio.conf se existir"

sudo cp -n /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak 2>/dev/null || true

echo "→ stow $PLYMOUTH_PKG (/)"
sudo $STOW $STOW_FLAGS --target=/ "$PLYMOUTH_PKG"

echo "→ Regerando initramfs"
sudo mkinitcpio -P

echo ""
echo "✅ Instalação concluída."

