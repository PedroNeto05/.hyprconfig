#!/bin/bash
set -e

echo "🔹 Verificando mkinitcpio.conf antes do stow"

# Backup mkinitcpio.conf se existir
if [ -f "/etc/mkinitcpio.conf" ]; then
    echo "🔹 Fazendo backup do mkinitcpio.conf atual"
    sudo mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup.$(date +%Y%m%d%H%M%S)
fi

echo "🔹 Aplicando dotfiles HOME"
stow --verbose home -t ~

echo "🔹 Aplicando dotfiles ETC"
sudo stow --verbose etc -t /

# =========================
# BACKUP DOS ARQUIVOS BOOT
# =========================

if [ -f "/boot/EFI/refind/refind.conf" ]; then
    echo "🔹 Fazendo backup do refind.conf"
    sudo mv /boot/EFI/refind/refind.conf /boot/EFI/refind/refind.conf.backup.$(date +%Y%m%d%H%M%S)
fi

if [ -f "/boot/refind_linux.conf" ]; then
    echo "🔹 Fazendo backup do refind_linux.conf"
    sudo mv /boot/refind_linux.conf /boot/refind_linux.conf.backup.$(date +%Y%m%d%H%M%S)
fi

if [ -d "boot" ]; then
    echo "🔹 Aplicando dotfiles BOOT"
    sudo stow --verbose boot -t /
fi

# Regen initramfs se mkinitcpio.conf estiver nos dotfiles
if [ -f "etc/etc/mkinitcpio.conf" ]; then
    echo "🔹 Regenerando initramfs"
    sudo mkinitcpio -P
fi

echo "✅ Concluído."

