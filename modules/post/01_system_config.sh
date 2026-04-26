#!/bin/bash

configure_post_installation() {
  echo "Configurando servicos do sistema..."
  sudo systemctl enable udisks2.service || true

  echo "Configurando permissoes globais do Flatpak (Teclado e Idioma)..."
  if command -v flatpak &>/dev/null; then
    flatpak override --user --env=LC_CTYPE=pt_BR.UTF-8
    flatpak override --user --env=GTK_IM_MODULE=cedilla
  else
    echo "Aviso: Flatpak nao encontrado. Pulando configuracao de override."
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

  if [ "$INSTALL_GRUB_BTRFS" = true ]; then
    echo "Habilitando servico grub-btrfsd..."
    sudo systemctl enable --now grub-btrfsd
    echo "Regenerando configuracao do GRUB..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi

  if [ "$INSTALL_SDDM" = true ]; then
    echo "Ativando o servico do SDDM..."
    sudo systemctl enable --now sddm
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
