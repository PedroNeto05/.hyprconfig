#!/bin/bash

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

if [ ! -d "$USER_SYSTEMD_DIR" ]; then
  echo "Erro: Pasta $USER_SYSTEMD_DIR nao encontrada."
  exit 1
fi

echo "Iniciando ativacao de daemons de usuario..."

cd "$USER_SYSTEMD_DIR" || exit 1

for service_file in *.service *.timer; do

  [ -e "$service_file" ] || continue

  echo "Ativando: $service_file"

  systemctl --user enable --now "$service_file"
done

echo "Todos os daemons foram processados"
