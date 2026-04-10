#!/bin/bash

set -e

# Configurações iniciais das flags
INSTALL_SDDM=false
INSTALL_PLYMOUTH=false
INSTALL_GRUB_BTRFS=false

# Interpretador de argumentos (flags)
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --sddm) INSTALL_SDDM=true ;;
  --plymouth) INSTALL_PLYMOUTH=true ;;
  -h | --help)
    echo "Uso: $0 [OPÇÕES]"
    echo "Opções:"
    echo "  --sddm      Instala o SDDM e ativa o serviço no systemd"
    echo "  --plymouth  Instala o Plymouth, instala o tema green-blocks e o define como padrão"
    echo "  -h, --help  Mostra esta mensagem de ajuda"
    exit 0
    ;;
  *)
    echo "⚠️ Parâmetro desconhecido: $1" >&2
    exit 1
    ;;
  esac
  shift
done

echo "🔹 Atualizando sistema com yay..."
yay -Syu --noconfirm

echo "🔹 Definindo lista de pacotes base..."

# Lista de pacotes base (sem SDDM e Plymouth)
PACKAGES=(
  hyprland
  hyprpicker
  qt6-svg
  qt6-multimedia-ffmpeg
  qt6-virtualkeyboard
  xf86-video-amdgpu
  ffmpeg
  gst-plugins-ugly
  gst-plugins-good
  gst-plugins-base
  gst-plugins-bad
  gst-libav
  gstreamer
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
  gvfs-mtp
  gvfs-smb
  udisks2
  gnome-keyring
  xdg-user-dirs
  nautilus
  nautilus-python
  dunst
  nautilus-image-converter
  wayland
  man-db
  man-pages
  hyprsunset
  neovim
  fish
  vesktop
  tmux
  lazygit
  starship
  asdf-vm
  fzf
  uv
  adw-gtk-theme
  flatpak
  breeze-icons
  obsidian
  inter-font
  ttf-noto-nerd
  ttf-icomoon-feather
  nwg-look
  qt5ct
  qt6ct
  kvantum
  kvantum-qt5
  qt5
  qt6-wayland
  bibata-cursor-theme-bin
  vlc-plugin-ffmpeg
  vlc
  eog
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
  mpv
  wf-recorder
)

# Condicionais para adicionar pacotes baseados nas flags
if [ "$INSTALL_SDDM" = true ]; then
  echo "🔹 Flag --sddm detectada: Adicionando SDDM à lista de instalação..."
  PACKAGES+=(sddm)
fi

if [ "$INSTALL_PLYMOUTH" = true ]; then
  echo "🔹 Flag --plymouth detectada: Adicionando Plymouth à lista de instalação..."
  PACKAGES+=(plymouth plymouth-theme-green-blocks-git)
fi

echo "🔹 Verificando se Snapper está presente..."

if command -v snapper &>/dev/null; then
  echo "✔ Snapper detectado."
  echo "🔹 Adicionando btrfs-assistant à lista de instalação..."
  PACKAGES+=(btrfs-assistant snap-pac)

  echo "🔹 Verificando se GRUB está presente para configurar grub-btrfs..."
  if [ -d "/boot/grub" ]; then
    echo "✔ GRUB detectado como bootloader."
    echo "🔹 Adicionando grub-btrfs à lista de instalação..."
    PACKAGES+=(grub-btrfs)
    INSTALL_GRUB_BTRFS=true
  else
    echo "ℹ GRUB não detectado. grub-btrfs não será configurado."
  fi
else
  echo "ℹ Snapper não detectado. btrfs-assistant e grub-btrfs não serão instalados."
fi

echo "🔹 Removendo duplicados..."
readarray -t PACKAGES < <(printf "%s\n" "${PACKAGES[@]}" | sort -u)

MISSING_PACKAGES=()

echo "🔹 Verificando pacotes instalados..."

for pkg in "${PACKAGES[@]}"; do
  if pacman -Qi "$pkg" &>/dev/null; then
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

sudo systemctl enable udisks2
flatpak install -y flathub app.zen_browser.zen

echo "🔹 Configurando permissões globais do Flatpak (Teclado e Idioma)..."
flatpak override --user --env=LC_CTYPE=pt_BR.UTF-8
flatpak override --user --env=GTK_IM_MODULE=cedilla

echo "🔹 Alterando shell padrão para fish..."
if command -v fish &>/dev/null; then
  chsh -s /usr/bin/fish
else
  echo "⚠️ Fish não está instalado."
fi

if [ "$INSTALL_PLYMOUTH" = true ]; then
  echo "🔹 Verificando temas disponíveis do Plymouth..."

  if plymouth-set-default-theme -l | grep -q green; then
    THEME=$(plymouth-set-default-theme -l | grep green | head -n1 | awk '{print $1}')
    echo "✔ Tema encontrado: $THEME"
    sudo plymouth-set-default-theme -R "$THEME"
  else
    echo "⚠ Tema green-blocks não encontrado."
  fi
fi

if [ "$INSTALL_GRUB_BTRFS" = true ]; then
  echo "🔹 Habilitando serviço grub-btrfsd..."
  sudo systemctl enable --now grub-btrfsd

  echo "🔹 Regenerando configuração do GRUB..."
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ "$INSTALL_SDDM" = true ]; then
  echo "🔹 Ativando o serviço do SDDM via systemctl..."
  sudo systemctl enable --now sddm
fi

xdg-user-dirs-update
nautilus -q

echo "✅ Instalação concluída!"
