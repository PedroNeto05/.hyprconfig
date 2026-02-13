#!/bin/bash

set -e

echo "🔹 Atualizando sistema..."
sudo pacman -Syu --noconfirm

echo "🔹 Verificando dependências essenciais..."
ESSENTIALS=(
    base-devel
    git
    wget
    curl
    unzip
    zip
    cmake
    stow
    openssh
)

# Array para armazenar pacotes que precisam ser instalados
MISSING_PACKAGES=()

for pkg in "${ESSENTIALS[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo "✔ $pkg já está instalado."
    else
        echo "→ $pkg precisa ser instalado."
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Instala todos os pacotes faltantes de uma vez
if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "🔹 Instalando pacotes faltantes de uma vez: ${MISSING_PACKAGES[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
else
    echo "✔ Todas as dependências essenciais já estão instaladas."
fi

echo "🔹 Verificando yay..."
if command -v yay &> /dev/null; then
    echo "✔ yay já está instalado."
else
    echo "→ Instalando yay no /tmp pelo método oficial..."

    cd /tmp
    [ -d /tmp/yay ] && rm -rf /tmp/yay

    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay

    makepkg -si --noconfirm

    cd ~
    rm -rf /tmp/yay

    echo "✔ yay instalado com sucesso."
fi

echo ""
echo "🔹 Executando script stow.sh..."

# Garante que o script existe
if [ -f "./stow.sh" ]; then
    chmod +x ./stow.sh
    ./stow.sh
else
    echo "❌ stow.sh não encontrado no diretório atual!"
    exit 1
fi


echo "✅ Pre-install concluído!"
