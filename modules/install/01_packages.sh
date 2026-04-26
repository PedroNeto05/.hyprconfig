#!/bin/bash

PKG_CORE_WAYLAND=(
  hyprland wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  xdg-desktop-portal xdg-desktop-portal-kde polkit polkit-gnome
)

PKG_DRIVERS_VIDEO=(
  mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu
)

PKG_AUDIO_MEDIA=(
  pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse
  pipewire-jack lib32-pipewire pavucontrol ffmpeg gst-plugins-ugly
  gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer
  vlc vlc-plugin-ffmpeg mpv playerctl
)

PKG_NETWORK_BLUETOOTH=(
  bluez bluez-utils blueman nm-connection-editor
)

PKG_HYPRLAND_TOOLS=(
  hyprpicker waybar hyprpaper hyprlock hypridle rofi wl-clipboard
  cliphist grim slurp dunst hyprsunset swappy wf-recorder
)

PKG_TERMINAL_DEV=(
  kitty neovim fish tmux lazygit starship asdf-vm fzf uv btop fd ripgrep tree bat
)

PKG_SYSTEM_TOOLS=(
  gvfs gvfs-mtp gvfs-smb udisks2 gnome-keyring xdg-user-dirs
  man-db man-pages zenity fuse2 flatpak
)

PKG_APPS=(
  zen-browser-bin vesktop obsidian nautilus nautilus-python
  nautilus-image-converter file-roller eog kcalc zathura zathura-pdf-mupd
)

PKG_THEMES_FONTS=(
  adw-gtk-theme nwg-look breeze-icons bibata-cursor-theme-bin
  qt5ct qt6ct kvantum kvantum-qt5 qt5 qt6-wayland qt6-svg
  qt6-multimedia-ffmpeg qt6-virtualkeyboard
  inter-font ttf-noto-nerd ttf-icomoon-feather noto-fonts noto-fonts-emoji
  noto-fonts-cjk ttf-liberation otf-font-awesome ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
)

PKG_MISC=(
  tesseract-data-eng tesseract-data-por
)

install_main_packages() {
  echo "Definindo lista de pacotes base..."

  local ALL_PACKAGES=(
    "${PKG_CORE_WAYLAND[@]}"
    "${PKG_DRIVERS_VIDEO[@]}"
    "${PKG_AUDIO_MEDIA[@]}"
    "${PKG_NETWORK_BLUETOOTH[@]}"
    "${PKG_HYPRLAND_TOOLS[@]}"
    "${PKG_TERMINAL_DEV[@]}"
    "${PKG_SYSTEM_TOOLS[@]}"
    "${PKG_APPS[@]}"
    "${PKG_THEMES_FONTS[@]}"
    "${PKG_MISC[@]}"
  )

  if [ "$INSTALL_SDDM" = true ]; then
    echo "Flag --sddm detectada: Adicionando SDDM..."
    ALL_PACKAGES+=(sddm)
  fi

  if [ "$INSTALL_PLYMOUTH" = true ]; then
    echo "Flag --plymouth detectada: Adicionando Plymouth..."
    ALL_PACKAGES+=(plymouth plymouth-theme-green-blocks-git)
  fi

  echo "Verificando se Snapper esta presente..."
  if command -v snapper &>/dev/null; then
    echo "Snapper detectado. Adicionando utilitarios btrfs..."
    ALL_PACKAGES+=(btrfs-assistant snap-pac)

    if [ -d "/boot/grub" ]; then
      echo "GRUB detectado como bootloader. Adicionando grub-btrfs..."
      ALL_PACKAGES+=(grub-btrfs)
      export INSTALL_GRUB_BTRFS=true
    else
      echo "GRUB nao detectado. grub-btrfs nao sera configurado."
    fi
  else
    echo "Snapper nao detectado. Pacotes btrfs extras ignorados."
  fi

  readarray -t ALL_PACKAGES < <(printf "%s\n" "${ALL_PACKAGES[@]}" | sort -u)

  local MISSING_PACKAGES=()
  echo "Verificando pacotes ja instalados..."

  for pkg in "${ALL_PACKAGES[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "$pkg ja esta instalado."
    else
      echo "$pkg sera instalado."
      MISSING_PACKAGES+=("$pkg")
    fi
  done

  if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "Instalando pacotes faltantes com yay..."
    yay -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
  else
    echo "Todos os pacotes ja estao instalados."
  fi
}
