#!/bin/bash

set -e

echo "🔹 Atualizando sistema com yay..."
yay -Syu --noconfirm

echo "🔹 Definindo lista de pacotes..."

PACKAGES=(
    hyprland
    sddm
    qt6-svg
    qt6-multimedia-ffmpeg
    qt6-virtualkeyboard
    xf86-video-amdgpu
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    fuse2
    pipewire
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    lib32-pipewire
    pavucontrol
    bluez
    bluez-utils
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    xdg-desktop-portal-kde
    polkit
    polkit-gnome
    blueman
    nm-connection-editor
    waybar
    kitty
    plymouth
    plymouth-theme-green-blocks-git
    hyprpaper
    hyprlock
    hypridle
    rofi
    wl-clipboard
    cliphist
    grim
    slurp
    file-roller
    gvfs
    gvfs-tmp
    gvfs-smb
    udisks2
    gnome-keyring
    xdg-user-dirs
    nautilus
    nautilus-python
    nautilus-image-converter
    wayland
    man-db
    man-pages
    neovim
    fish
    tmux
    lazygit
    starship
    eye-of-gnome
    asdf-vm
    fzf
    uv
    adw-gtk-theme
    flatpak
    breeze-icons
    inter-font
    ttf-noto-nerd
    ttf-icomoon-feather
    ngw-look
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
    qt5
    qt6-wayland
    bibata-cursor-theme-bin
    vlc-plugin-ffmpeg
    btop
    fd
    ripgrep
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    ttf-liberation
    otf-font-awesome
    ttf-jetbrains-mono
    ttf-jetbrains-mono-nerd
)

echo "🔹 Removendo duplicados..."
readarray -t PACKAGES < <(printf "%s\n" "${PACKAGES[@]}" | sort -u)

MISSING_PACKAGES=()

echo "🔹 Verificando pacotes instalados..."

for pkg in "${PACKAGES[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo "✔ $pkg já está instalado."
    else
        echo "→ $pkg será instalado."
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "🔹 Instalando pacotes faltantes com yay..."
    yay -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
else
    echo "✔ Todos os pacotes já estão instalados."
fi

echo "✅ Instalação concluída!"

