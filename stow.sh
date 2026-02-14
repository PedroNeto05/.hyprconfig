#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Iniciando deploy dos dotfiles"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# =========================
# VERIFICAÇÕES INICIAIS
# =========================
if ! command -v stow >/dev/null 2>&1; then
    echo "❌ GNU Stow não está instalado."
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "❌ rsync não está instalado."
    exit 1
fi

# =========================
# BACKUP mkinitcpio.conf
# =========================
if [ -f "/etc/mkinitcpio.conf" ]; then
    echo "🔹 Backup de /etc/mkinitcpio.conf"
    sudo cp /etc/mkinitcpio.conf \
        /etc/mkinitcpio.conf.backup."$TIMESTAMP"
fi

# =========================
# STOW HOME
# =========================
if [ -d "$DOTFILES/home" ]; then
    echo "🔹 Aplicando dotfiles HOME"
    stow --verbose --restow home -t ~
fi

# =========================
# STOW ETC
# =========================
if [ -d "$DOTFILES/etc" ]; then
    echo "🔹 Aplicando dotfiles ETC"
    sudo stow --verbose --restow etc -t /
fi

# =========================
# BACKUP BOOT (rEFInd)
# =========================
if [ -f "/boot/EFI/refind/refind.conf" ]; then
    echo "🔹 Backup refind.conf"
    sudo cp /boot/EFI/refind/refind.conf \
        /boot/EFI/refind/refind.conf.backup."$TIMESTAMP"
fi

if [ -f "/boot/refind_linux.conf" ]; then
    echo "🔹 Backup refind_linux.conf"
    sudo cp /boot/refind_linux.conf \
        /boot/refind_linux.conf.backup."$TIMESTAMP"
fi

# =========================
# DEPLOY BOOT VIA RSYNC
# Estrutura esperada:
# .dotfiles/boot/boot/*
# =========================
if [ -d "$DOTFILES/boot/boot" ]; then
    echo "🔹 Aplicando dotfiles BOOT via rsync"
    sudo rsync -av --delete \
        "$DOTFILES/boot/boot/" \
        /boot/
else
    echo "⚠ Diretório boot/boot não encontrado — pulando BOOT"
fi

# =========================
# REGENERAR INITRAMFS
# =========================
if [ -f "$DOTFILES/etc/mkinitcpio.conf" ]; then
    echo "🔹 Regenerando initramfs"
    sudo mkinitcpio -P
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deploy concluído com sucesso."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

