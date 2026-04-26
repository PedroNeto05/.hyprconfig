#!/bin/bash

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

if [ ! -d "$USER_SYSTEMD_DIR" ]; then
  echo "Erro: Pasta $USER_SYSTEMD_DIR nao encontrada."
  exit 1
fi

echo "Iniciando ativacao de daemons de usuario..."

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

cd "$USER_SYSTEMD_DIR" || exit 1

for service_file in *.service *.timer; do
  [ -e "$service_file" ] || continue

  echo "Ativando: $service_file"
  systemctl --user enable --now "$service_file" || echo "Aviso: Falha ao ativar $service_file"
done

echo "Todos os daemons foram processados"
