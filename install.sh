#!/bin/bash
set -e

export DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export INSTALL_SDDM=false
export INSTALL_PLYMOUTH=false
export INSTALL_GRUB_BTRFS=false
export INSTALL_GAMING=false
export CACHYOS_AVAILABLE=false

# Override manual da deteccao de hardware (vazio = detecta automaticamente).
export FORCE_CPU_VENDOR=""
export FORCE_GPU_VENDOR=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
  --sddm) export INSTALL_SDDM=true ;;
  --plymouth) export INSTALL_PLYMOUTH=true ;;
  --gaming) export INSTALL_GAMING=true ;;
  --cpu)
    shift
    case "$1" in
    amd | intel) export FORCE_CPU_VENDOR="$1" ;;
    *)
      echo "Valor invalido para --cpu: '$1' (use amd ou intel)" >&2
      exit 1
      ;;
    esac
    ;;
  --gpu)
    shift
    case "$1" in
    amd | intel | nvidia) export FORCE_GPU_VENDOR="$1" ;;
    *)
      echo "Valor invalido para --gpu: '$1' (use amd, intel ou nvidia)" >&2
      exit 1
      ;;
    esac
    ;;
  -h | --help)
    echo "Uso: $0 [OPCOES]"
    echo "Opcoes:"
    echo "  --sddm        Instala o SDDM e ativa o servico no systemd"
    echo "  --plymouth    Instala o Plymouth, instala o tema green-blocks e o define como padrao"
    echo "  --gaming      Instala pacotes de jogos no lugar dos apps de produtividade"
    echo "  --cpu VENDOR  Forca o microcode da CPU (amd|intel) em vez de detectar"
    echo "  --gpu VENDOR  Forca os drivers da GPU (amd|intel|nvidia) em vez de detectar"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo
    echo "Sem --cpu/--gpu o hardware e detectado automaticamente."
    exit 0
    ;;
  *)
    echo "Parametro desconhecido: $1" >&2
    exit 1
    ;;
  esac
  shift
done

source "$SCRIPT_DIR/modules/install/00_hardware.sh"
source "$SCRIPT_DIR/modules/install/02_cachyos.sh"
source "$SCRIPT_DIR/modules/install/01_packages.sh"
source "$SCRIPT_DIR/modules/post/01_system_config.sh"

echo "Atualizando sistema com yay..."
yay -Syu --noconfirm

# No modo gaming, adiciona o repo do CachyOS antes de instalar os pacotes (o
# kernel linux-cachyos so entra na lista se o repo for adicionado com sucesso).
if [ "$INSTALL_GAMING" = true ]; then
  if setup_cachyos_repo; then
    export CACHYOS_AVAILABLE=true
  fi
fi

install_main_packages

configure_post_installation
