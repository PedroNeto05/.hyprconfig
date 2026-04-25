#!/bin/bash

configure_post_installation() {
  echo "Configurando servicos do sistema..."
  sudo systemctl enable udisks2

  echo "Configurando permissoes globais do Flatpak (Teclado e Idioma)..."
  flatpak override --user --env=LC_CTYPE=pt_BR.UTF-8
  flatpak override --user --env=GTK_IM_MODULE=cedilla

  echo "Alterando shell padrao para fish..."
  if command -v fish &>/dev/null; then
    chsh -s /usr/bin/fish
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
  xdg-user-dirs-update
  nautilus -q || true
  xdg-mime default org.gnome.Nautilus.desktop inode/directory

  echo "Sincronizando dependencias Python (uv) no Nautilus custom scripts..."
  if [ -d "$HOME/.config/nautilus-custom-scripts" ]; then
    cd "$HOME/.config/nautilus-custom-scripts"
    uv sync
  else
    echo "Diretorio do nautilus-custom-scripts nao encontrado em $HOME/.config/"
  fi

  local INSTALLER="$SCRIPT_DIR/modules/post/02_daemons.sh"
  if [ -x "$INSTALLER" ]; then
    echo "Iniciando ativacao dos servicos via 02_daemons.sh..."
    "$INSTALLER"
  else
    echo "Erro: O script $INSTALLER nao foi encontrado ou nao tem permissao de execucao."
  fi

  echo "Instalacao e configuracao concluidas com sucesso!"
}
