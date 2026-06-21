#!/bin/bash
#
# Adiciona o repositorio binario do CachyOS (kernel otimizado para jogos).
# Usado apenas no modo --gaming. Usa o script oficial do CachyOS, que detecta
# automaticamente o nivel de instrucao da CPU (x86-64-v3 / v4 / znver4) e
# importa a chave GPG do repositorio.
#
# O kernel em si (linux-cachyos + linux-cachyos-headers) e instalado depois,
# via PKG_GAMING em 01_packages.sh.

setup_cachyos_repo() {
  # Idempotente: se o repo ja esta no pacman.conf, nao faz nada.
  if grep -q "cachyos" /etc/pacman.conf 2>/dev/null; then
    echo "Repositorio CachyOS ja configurado. Pulando..."
    return 0
  fi

  echo "Adicionando o repositorio CachyOS (script oficial)..."
  local tmp
  tmp=$(mktemp -d)

  if ! curl -fsSL https://mirror.cachyos.org/cachyos-repo.tar.xz \
    -o "$tmp/cachyos-repo.tar.xz"; then
    echo "Aviso: falha ao baixar o script do CachyOS. O kernel cachyos sera ignorado." >&2
    rm -rf "$tmp"
    return 1
  fi

  tar xf "$tmp/cachyos-repo.tar.xz" -C "$tmp"

  if (cd "$tmp/cachyos-repo" && sudo ./cachyos-repo.sh --install); then
    echo "Repositorio CachyOS adicionado com sucesso."
  else
    echo "Aviso: o script do CachyOS falhou. O kernel cachyos sera ignorado." >&2
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$tmp"
}
