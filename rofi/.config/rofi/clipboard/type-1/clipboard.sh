#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x) & Unificado via Gemini
## Github : @adi1090x
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)

# ==========================================
# CONFIGURAÇÕES DO ROFI
# ==========================================
dir="$HOME/.config/rofi/clipboard/type-1"
theme='style-1'
tmp_dir="/tmp/cliphist"

# ==========================================
# FASE 1: INICIAR O ROFI
# Se ROFI_RETV estiver vazio, o script foi chamado pelo usuário/atalho.
# ==========================================
if [[ -z "$ROFI_RETV" ]]; then
  # Pega o caminho absoluto deste próprio arquivo
  SCRIPT_PATH=$(realpath "$0")

  # Roda o Rofi usando este mesmo script como o módulo "clipboard"
  rofi \
    -modi "clipboard:$SCRIPT_PATH" \
    -show clipboard \
    -show-icons \
    -theme "${dir}/${theme}.rasi"

  # Limpa a pasta temporária após o Rofi fechar
  rm -rf "$tmp_dir"
  exit 0
fi

# ==========================================
# FASE 2: LIDAR COM A SELEÇÃO
# Se $1 não estiver vazio, significa que o usuário clicou em um item no Rofi.
# ==========================================
if [[ -n "$1" ]]; then
  item_data=$(echo "$1" | sed -E 's/^[0-9]+[[:space:]]+//')

  filepath=""
  if [[ "$item_data" == file://* ]]; then
    filepath="${item_data#file://}"
  elif [[ "$item_data" == /* ]]; then
    filepath="$item_data"
  fi

  if [[ -n "$filepath" ]]; then
    filepath=$(echo -n "$filepath" | tr -d '\r\n')

    filepath=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$filepath")

    if [[ -f "$filepath" ]]; then
      mime_type=$(file --mime-type -b "$filepath")

      # Se for imagem, copia os dados binários
      if [[ "$mime_type" == image/* ]]; then
        wl-copy --type "$mime_type" <"$filepath"
        exit 0
      # Se for vídeo, copia como arquivo (URI) para poder colar no Discord/Nautilus
      elif [[ "$mime_type" == video/* ]]; then
        echo -n "file://$filepath" | wl-copy -t text/uri-list
        exit 0
      fi
    fi
  fi

  cliphist decode <<<"$1" | wl-copy
  exit 0
fi

# ==========================================
# FASE 3: GERAR A LISTA PARA O ROFI
# ==========================================
mkdir -p "$tmp_dir"

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }

# Imagens binárias em base64
match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0"\0icon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}

# Caminhos file:// para Imagens
match(\$0, /^([0-9]+)\s+file:\/\/(.*(jpg|jpeg|png|bmp|gif|webp))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    gsub(/%20/, " ", path)
    print \$0"\0icon\x1f"path
    next
}

# Caminhos absolutos (/) para Imagens
match(\$0, /^([0-9]+)\s+(\/.*(jpg|jpeg|png|bmp|gif|webp))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    print \$0"\0icon\x1f"path
    next
}

# Caminhos file:// para Vídeos
match(\$0, /^([0-9]+)\s+file:\/\/(.*(mp4|webm|mkv|mov))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    gsub(/%20/, " ", path)
    print \$0"\0icon\x1fvideo-x-generic"
    next
}

# Caminhos absolutos (/) para Vídeos
match(\$0, /^([0-9]+)\s+(\/.*(mp4|webm|mkv|mov))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    print \$0"\0icon\x1fvideo-x-generic"
    next
}

1
EOF

cliphist list | head -n 500 | gawk "$prog"
