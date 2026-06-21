#!/bin/bash

configure_post_installation() {
  echo "Configurando servicos do sistema..."
  sudo systemctl enable udisks2.service || true

  echo "Habilitando otimizacoes de desempenho/responsividade..."
  if pacman -Qq ananicy-cpp &>/dev/null; then
    sudo systemctl enable --now ananicy-cpp.service || true
  fi
  if pacman -Qq earlyoom &>/dev/null; then
    sudo systemctl enable --now earlyoom.service || true
  fi

  if pacman -Qq corectrl &>/dev/null; then
    echo "Configurando regra polkit do CoreCtrl (aplicar perfis sem senha)..."
    sudo tee /etc/polkit-1/rules.d/90-corectrl.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.corectrl.helper.init" ||
         action.id == "org.corectrl.helperkiller.init") &&
        subject.local == true &&
        subject.active == true &&
        subject.isInGroup("wheel")) {
            return polkit.Result.YES;
    }
});
EOF
  fi

  echo "Configurando manutencao automatica do sistema..."
  if pacman -Qq reflector &>/dev/null; then
    echo "Definindo reflector (mirrors do Brasil) e habilitando timer..."
    sudo mkdir -p /etc/xdg/reflector
    sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<'EOF'
--save /etc/pacman.d/mirrorlist
--country BR,US
--protocol https
--latest 20
--sort rate
EOF
    sudo systemctl enable reflector.timer || true
  fi

  if pacman -Qq pacman-contrib &>/dev/null; then
    echo "Habilitando limpeza automatica do cache do pacman (paccache.timer)..."
    sudo systemctl enable paccache.timer || true
  fi

  echo "Configurando o Flatpak..."
  if command -v flatpak &>/dev/null; then
    echo "Garantindo o repositorio Flathub..."
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo || true

    echo "Definindo permissoes globais do Flatpak (Teclado e Idioma)..."
    flatpak override --user --env=LC_CTYPE=pt_BR.UTF-8
    flatpak override --user --env=GTK_IM_MODULE=cedilla

    echo "Instalando o Flatseal (gerenciador de permissoes do Flatpak)..."
    flatpak install -y flathub com.github.tchx84.Flatseal ||
      echo "Aviso: falha ao instalar o Flatseal."
  else
    echo "Aviso: Flatpak nao encontrado. Pulando configuracao do Flatpak."
  fi

  echo "Alterando shell padrao para fish..."
  if command -v fish &>/dev/null; then
    sudo chsh -s /usr/bin/fish "$USER"
  else
    echo "Fish nao esta instalado."
  fi

  if [ "$INSTALL_PLYMOUTH" = true ]; then
    echo "Verificando temas disponiveis do Plymouth..."
    if plymouth-set-default-theme -l | grep -q green; then
      THEME=$(plymouth-set-default-theme -l | grep green | head -n1 | awk '{print $1}')
      echo "Tema encontrado: $THEME"
      sudo plymouth-set-default-theme -R "$THEME"
    else
      echo "Tema green-blocks nao encontrado."
    fi
  fi

  if [ "$INSTALL_GAMING" = true ]; then
    echo "Configurando ambiente de jogos..."

    if [ "$CACHYOS_AVAILABLE" = true ] && pacman -Qq linux-cachyos &>/dev/null; then
      if [ -d /boot/grub ]; then
        echo "Regenerando o GRUB para incluir o kernel CachyOS..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg || true
        echo "Kernel CachyOS instalado. Para torna-lo padrao de boot, veja o README."
      fi
    fi

    if getent group gamemode &>/dev/null; then
      echo "Adicionando $USER ao grupo gamemode..."
      sudo usermod -aG gamemode "$USER" || true
    fi
  fi

  if [ "$INSTALL_GRUB_BTRFS" = true ]; then
    echo "Habilitando servico grub-btrfsd..."
    sudo systemctl enable --now grub-btrfsd
    echo "Regenerando configuracao do GRUB..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi

  if pacman -Qq sddm &>/dev/null; then
    echo "Ativando o servico do SDDM (display manager padrao)..."
    sudo systemctl enable sddm
  fi

  echo "Configurando diretorios padrao de usuario e Nautilus..."
  if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
  fi

  if command -v nautilus &>/dev/null; then
    nautilus -q || true
  fi

  if command -v xdg-mime &>/dev/null; then
    xdg-mime default org.gnome.Nautilus.desktop inode/directory
  fi

  echo "Sincronizando dependencias Python (uv) no Nautilus custom scripts..."
  local NAUTILUS_DIR="$HOME/.config/nautilus-custom-scripts"
  if [ -d "$NAUTILUS_DIR" ]; then
    if command -v uv &>/dev/null; then
      echo "Comando uv encontrado. Iniciando sync..."
      (
        cd "$NAUTILUS_DIR" || exit 1
        uv sync || echo "Aviso: Falha ao rodar uv sync. O script vai continuar."
      )
    else
      echo "Erro: O pacote 'uv' nao foi encontrado no sistema."
    fi
  else
    echo "Diretorio $NAUTILUS_DIR nao encontrado."
  fi

  local INSTALLER="$SCRIPT_DIR/modules/post/02_daemons.sh"
  if [ -f "$INSTALLER" ]; then
    echo "Iniciando ativacao dos servicos via 02_daemons.sh..."
    bash "$INSTALLER"
  else
    echo "Erro: O script $INSTALLER nao foi encontrado."
  fi

  echo "Instalacao e configuracao concluidas com sucesso!"
}
