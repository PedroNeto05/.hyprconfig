#!/bin/bash

PKG_CORE_WAYLAND=(
  hyprland wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  xdg-desktop-portal xdg-desktop-portal-kde polkit polkit-gnome
)

# Os drivers de video e o microcode da CPU sao definidos dinamicamente por
# modules/install/00_hardware.sh (deteccao automatica ou flags --cpu/--gpu).

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
  zen-browser-bin vesktop nautilus nautilus-python file-roller eog kcalc
)

PKG_THEMES_FONTS=(
  adw-gtk-theme nwg-look breeze-icons bibata-cursor-theme-bin
  qt5ct qt6ct kvantum kvantum-qt5 qt5 qt6-wayland qt6-svg
  qt6-multimedia-ffmpeg qt6-virtualkeyboard
  inter-font ttf-noto-nerd ttf-icomoon-feather noto-fonts noto-fonts-emoji
  noto-fonts-cjk ttf-liberation otf-font-awesome ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
)

# Apps de produtividade/trabalho - instalados apenas no modo padrao (sem --gaming)
PKG_DESKTOP=(
  obsidian xournalpp nautilus-image-converter
  zathura zathura-pdf-mupdf
  tesseract-data-eng tesseract-data-por
)

# Pacotes de jogos - instalados apenas com a flag --gaming
PKG_GAMING=(
  steam steam-native-runtime
  gamemode lib32-gamemode
  mangohud lib32-mangohud
  lutris heroic-games-launcher-bin
  gamescope gamescope-session
  vkbasalt lib32-vkbasalt
  goverlay
  xpadneo-dkms game-devices-udev
)

# Otimizacao de desempenho/responsividade e ferramentas de hardware (AMD)
PKG_OPTIMIZATION=(
  ananicy-cpp earlyoom corectrl radeontop vulkan-tools
)

# Manutencao do sistema (mirrors, cache, AUR rebuilds, downgrade)
PKG_MAINTENANCE=(
  reflector pacman-contrib rebuild-detector downgrade
)

# Ferramentas de linha de comando (a config do shell fica no repo .dotfiles)
PKG_CLI=(
  zoxide
)

install_main_packages() {
  echo "Definindo lista de pacotes base..."

  echo "Detectando hardware (CPU/GPU)..."
  collect_hardware_packages

  local ALL_PACKAGES=(
    "${PKG_CORE_WAYLAND[@]}"
    "${HARDWARE_PACKAGES[@]}"
    "${PKG_AUDIO_MEDIA[@]}"
    "${PKG_NETWORK_BLUETOOTH[@]}"
    "${PKG_HYPRLAND_TOOLS[@]}"
    "${PKG_TERMINAL_DEV[@]}"
    "${PKG_SYSTEM_TOOLS[@]}"
    "${PKG_APPS[@]}"
    "${PKG_THEMES_FONTS[@]}"
    "${PKG_OPTIMIZATION[@]}"
    "${PKG_MAINTENANCE[@]}"
    "${PKG_CLI[@]}"
  )

  if [ "$INSTALL_GAMING" = true ]; then
    echo "Flag --gaming detectada: Adicionando pacotes de jogos..."
    ALL_PACKAGES+=("${PKG_GAMING[@]}")

    if [ "$CACHYOS_AVAILABLE" = true ]; then
      echo "Repositorio CachyOS disponivel: Adicionando kernel linux-cachyos..."
      ALL_PACKAGES+=(linux-cachyos linux-cachyos-headers)
    fi
  else
    echo "Modo padrao: Adicionando apps de produtividade..."
    ALL_PACKAGES+=("${PKG_DESKTOP[@]}")
  fi

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

  # Se houver qualquer pacote DKMS (ex: nvidia-dkms, xpadneo-dkms), garante os
  # headers do(s) kernel(s) instalado(s), necessarios para compilar via DKMS.
  if printf '%s\n' "${ALL_PACKAGES[@]}" | grep -q -- '-dkms$'; then
    echo "Pacotes DKMS detectados. Adicionando headers do kernel..."
    for k in linux linux-lts linux-zen linux-hardened; do
      if pacman -Qq "$k" &>/dev/null; then
        ALL_PACKAGES+=("${k}-headers")
      fi
    done
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
