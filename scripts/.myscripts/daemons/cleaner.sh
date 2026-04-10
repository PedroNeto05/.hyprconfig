#!/bin/bash

DIAS=14
PASTAS=(
  "$HOME/Pictures/screenshots/"
)

# Verifica dependência silenciosamente
command -v fd >/dev/null 2>&1 || exit 1

for pasta in "${PASTAS[@]}"; do
  # Verifica se o diretório existe e se não está vazio
  if [ -d "$pasta" ]; then
    # --absolute-path ajuda a evitar ambiguidades em execução via daemon
    # -0 (print0) com xargs é mais seguro para nomes de arquivos estranhos
    fd . "$pasta" \
      --type file \
      --hidden \
      --no-ignore \
      --changed-before "${DIAS}d" \
      --exec-batch rm -f
  fi
done
