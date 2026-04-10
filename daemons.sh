#!/bin/bash

# Define a pasta de serviços do usuário
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

# Verifica se a pasta existe
if [ ! -d "$USER_SYSTEMD_DIR" ]; then
  echo "Erro: Pasta $USER_SYSTEMD_DIR não encontrada."
  exit 1
fi

echo "Iniciando ativação de daemons de usuário..."

# Entra na pasta para facilitar a manipulação dos nomes
cd "$USER_SYSTEMD_DIR" || exit 1

# Loop por todos os arquivos .service e .timer
for service_file in *.service *.timer; do

  # Verifica se o arquivo realmente existe (evita erro se a pasta estiver vazia)
  [ -e "$service_file" ] || continue

  echo "Ativando: $service_file"

  # --user: Executa no contexto do usuário
  # enable: Configura para iniciar no boot
  # --now: Inicia o serviço imediatamente
  systemctl --user enable --now "$service_file"
done

echo "Todos os daemons foram processados!"
