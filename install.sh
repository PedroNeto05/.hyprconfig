#!/bin/bash
set -e

export DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export INSTALL_SDDM=false
export INSTALL_PLYMOUTH=false
export INSTALL_GRUB_BTRFS=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
  --sddm) export INSTALL_SDDM=true ;;
  --plymouth) export INSTALL_PLYMOUTH=true ;;
  -h | --help)
    echo "Uso: $0 [OPCOES]"
    echo "Opcoes:"
    echo "  --sddm      Instala o SDDM e ativa o servico no systemd"
    echo "  --plymouth  Instala o Plymouth, instala o tema green-blocks e o define como padrao"
    echo "  -h, --help  Mostra esta mensagem de ajuda"
    exit 0
    ;;
  *)
    echo "Parametro desconhecido: $1" >&2
    exit 1
    ;;
  esac
  shift
done

source "$SCRIPT_DIR/modules/install/01_packages.sh"
source "$SCRIPT_DIR/modules/post/01_system_config.sh"

echo "Atualizando sistema com yay..."
yay -Syu --noconfirm

install_main_packages

configure_post_installation
