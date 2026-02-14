#!/bin/bash
set -e

echo "🔹 Verificando mkinitcpio.conf antes do stow"

# Se existir mkinitcpio.conf no sistema, mover para backup
if [ -f "/etc/mkinitcpio.conf" ]; then
    echo "🔹 Fazendo backup do mkinitcpio.conf atual"
    sudo mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup.$(date +%Y%m%d%H%M%S)
fi

echo "🔹 Aplicando dotfiles HOME"
stow --verbose home -t ~

echo "🔹 Aplicando dotfiles ETC"
sudo stow --verbose etc -t /

if [ -d "boot" ]; then
    echo "🔹 Aplicando dotfiles BOOT"
    sudo stow --verbose boot -t /
fi

# Só regenere initramfs se mkinitcpio.conf existir no stow
if [ -f "etc/etc/mkinitcpio.conf" ]; then
    echo "🔹 Regenerando initramfs"
    sudo mkinitcpio -P
fi

echo "✅ Concluído."

