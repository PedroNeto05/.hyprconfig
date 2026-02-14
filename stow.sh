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
for cmd in stow rsync; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ $cmd não está instalado."
        exit 1
    fi
done

# =========================
# GARANTIR QUE EFI ESTÁ MONTADA
# =========================
if ! mountpoint -q /boot; then
    echo "❌ /boot não está montado!"
    exit 1
fi

# =========================
# BACKUP mkinitcpio.conf (USANDO MV)
# =========================
if [ -f "/etc/mkinitcpio.conf" ]; then
    echo "🔹 Backup de /etc/mkinitcpio.conf"
    sudo mv /etc/mkinitcpio.conf \
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
# BACKUP rEFInd (USANDO MV)
# =========================
if [ -f "/boot/EFI/refind/refind.conf" ]; then
    echo "🔹 Backup refind.conf"
    sudo mv /boot/EFI/refind/refind.conf \
        /boot/EFI/refind/refind.conf.backup."$TIMESTAMP"
fi

if [ -f "/boot/refind_linux.conf" ]; then
    echo "🔹 Backup refind_linux.conf"
    sudo mv /boot/refind_linux.conf \
        /boot/refind_linux.conf.backup."$TIMESTAMP"
fi

# =========================
# DEPLOY rEFInd (APENAS EFI/refind)
# =========================
# Estrutura esperada:
# .dotfiles/boot/boot/EFI/refind/*
# =========================
if [ -d "$DOTFILES/boot/boot/EFI/refind" ]; then
    echo "🔹 Aplicando rEFInd via rsync (modo seguro EFI)"

    sudo rsync -rltv \
        --delete \
        --no-owner \
        --no-group \
        --no-perms \
        "$DOTFILES/boot/boot/EFI/refind/" \
        /boot/EFI/refind/

else
    echo "⚠ Diretório boot/boot/EFI/refind não encontrado — pulando BOOT"
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

