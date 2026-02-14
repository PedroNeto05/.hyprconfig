#!/bin/bash
set -e

DOTFILES="$HOME/.dotfiles"

echo "🔹 Verificando mkinitcpio.conf antes do stow"

# =========================
# BACKUP mkinitcpio.conf
# =========================
if [ -f "/etc/mkinitcpio.conf" ]; then
    echo "🔹 Fazendo backup do mkinitcpio.conf atual"
    sudo mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup.$(date +%Y%m%d%H%M%S)
fi

# =========================
# STOW HOME
# =========================
echo "🔹 Aplicando dotfiles HOME"
stow --verbose home -t ~

# =========================
# STOW ETC
# =========================
echo "🔹 Aplicando dotfiles ETC"
sudo stow --verbose etc -t /

# =========================
# BACKUP BOOT (rEFInd)
# =========================
if [ -f "/boot/EFI/refind/refind.conf" ]; then
    echo "🔹 Fazendo backup do refind.conf"
    sudo mv /boot/EFI/refind/refind.conf \
        /boot/EFI/refind/refind.conf.backup.$(date +%Y%m%d%H%M%S)
fi

if [ -f "/boot/refind_linux.conf" ]; then
    echo "🔹 Fazendo backup do refind_linux.conf"
    sudo mv /boot/refind_linux.conf \
        /boot/refind_linux.conf.backup.$(date +%Y%m%d%H%M%S)
fi

# =========================
# DEPLOY BOOT VIA RSYNC
# =========================
if [ -d "$DOTFILES/boot/EFI" ]; then
    echo "🔹 Aplicando dotfiles BOOT via rsync"
    sudo rsync -av --delete \
        "$DOTFILES/boot/EFI/" \
        /boot/EFI/
fi

# =========================
# REGENERAR INITRAMFS
# =========================
if [ -f "$DOTFILES/etc/mkinitcpio.conf" ]; then
    echo "🔹 Regenerando initramfs"
    sudo mkinitcpio -P
fi

echo "✅ Concluído."

