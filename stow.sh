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

if [ ! -d "$DOTFILES" ]; then
    echo "❌ Diretório de dotfiles ($DOTFILES) não encontrado!"
    exit 1
fi

# =========================
# GARANTIR QUE EFI ESTÁ MONTADA
# =========================
if ! mountpoint -q /boot; then
    echo "❌ /boot não está montado!"
    exit 1
fi

# =========================
# BACKUP E STOW: ETC (mkinitcpio e outros)
# =========================
if [ -d "$DOTFILES/etc" ]; then
    # Faz backup do mkinitcpio apenas se existir no sistema, se não for já um symlink,
    # e garantindo que temos uma versão no dotfiles para substituir.
    if [ -f "$DOTFILES/etc/mkinitcpio.conf" ] && [ -f "/etc/mkinitcpio.conf" ] && [ ! -L "/etc/mkinitcpio.conf" ]; then
        echo "🔹 Backup de /etc/mkinitcpio.conf"
        sudo mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup."$TIMESTAMP"
    fi

    echo "🔹 Aplicando dotfiles ETC"
    # A flag -d diz ao stow onde estão os pacotes
    sudo stow -d "$DOTFILES" --verbose --restow etc -t /
fi

# =========================
# STOW: HOME
# =========================
if [ -d "$DOTFILES/home" ]; then
    echo "🔹 Aplicando dotfiles HOME"
    stow -d "$DOTFILES" --verbose --restow home -t ~
fi

# =========================
# BACKUP E DEPLOY: rEFInd (BOOT)
# =========================
if [ -d "$DOTFILES/boot/boot/EFI/refind" ]; then
    # Backup refind.conf (ignorando se já for um arquivo do rsync de antes, mas o rsync
    # sobrescreve de forma limpa de qualquer jeito. O backup via mv previne problemas).
    if [ -f "/boot/EFI/refind/refind.conf" ]; then
        echo "🔹 Backup refind.conf"
        sudo mv /boot/EFI/refind/refind.conf /boot/EFI/refind/refind.conf.backup."$TIMESTAMP"
    fi

    echo "🔹 Aplicando rEFInd via rsync (modo seguro EFI)"
    sudo rsync -rltv \
        --delete \
        --no-owner \
        --no-group \
        --no-perms \
        "$DOTFILES/boot/boot/EFI/refind/" \
        /boot/EFI/refind/
else
    echo "⚠ Diretório boot/boot/EFI/refind não encontrado no .dotfiles — pulando"
fi

# Trata o refind_linux.conf isoladamente na raiz do /boot
if [ -f "$DOTFILES/boot/boot/refind_linux.conf" ]; then
    if [ -f "/boot/refind_linux.conf" ]; then
        echo "🔹 Backup refind_linux.conf"
        sudo mv /boot/refind_linux.conf /boot/refind_linux.conf.backup."$TIMESTAMP"
    fi
    echo "🔹 Restaurando refind_linux.conf"
    sudo cp "$DOTFILES/boot/boot/refind_linux.conf" /boot/refind_linux.conf
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
