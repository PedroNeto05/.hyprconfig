#!/bin/bash
set -e

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

