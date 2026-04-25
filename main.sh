#!/bin/bash
set -e

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

source ./packages.sh
source ./post_install.sh

echo "Atualizando sistema com yay..."
yay -Syu --noconfirm

install_all_packages

run_post_install
