dir="$HOME/.config/rofi/clipboard/type-1"
theme='style-1'
tmp_dir="/tmp/cliphist"

if [[ -z "$ROFI_RETV" ]]; then
  SCRIPT_PATH=$(realpath "$0")

  rofi \
    -modi "clipboard:$SCRIPT_PATH" \
    -show clipboard \
    -show-icons \
    -theme "${dir}/${theme}.rasi"

  rm -rf "$tmp_dir"
  exit 0
fi

if [[ -n "$1" ]]; then
  id=$(echo "$1" | grep -oE '^[0-9]+')

  if [[ -n "$id" ]]; then
    original_line=$(cliphist list | grep "^${id}[[:space:]]")
    item_data=$(echo "$original_line" | sed -E 's/^[0-9]+[[:space:]]+//')
  else
    item_data=$(echo "$1" | sed -E 's/^[0-9]+[[:space:]]+//')
  fi

  filepath=""
  if [[ "$item_data" == file://* ]]; then
    filepath="${item_data#file://}"
  elif [[ "$item_data" == /* ]]; then
    filepath="$item_data"
  fi

  if [[ -n "$filepath" ]]; then
    filepath=$(echo -n "$filepath" | tr -d '\r\n')
    filepath=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$filepath")

    if [[ -e "$filepath" ]]; then

      if [[ -d "$filepath" ]]; then
        echo -n "file://$filepath" | wl-copy -t text/uri-list
        exit 0
      fi

      if [[ -f "$filepath" ]]; then
        mime_type=$(file --mime-type -b "$filepath")

        if [[ "$mime_type" == image/* ]]; then
          wl-copy --type "$mime_type" <"$filepath"
          exit 0
        elif [[ "$mime_type" == video/* ]]; then
          echo -n "file://$filepath" | wl-copy -t text/uri-list
          exit 0
        else
          echo -n "file://$filepath" | wl-copy -t text/uri-list
          exit 0
        fi
      fi
    fi
  fi

  if [[ -n "$id" ]]; then
    cliphist decode <<<"$id" | wl-copy
  else
    cliphist decode <<<"$1" | wl-copy
  fi
  exit 0
fi

mkdir -p "$tmp_dir"

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }

match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0 "\0display\x1f[Binary Image] (" toupper(grp[3]) ")\x1ficon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}

match(\$0, /^([0-9]+)\s+(file:\/\/)?(\/.+)/, grp) {
    path = grp[3]
    
    gsub(/[\r\n]/, "", path)

    decoded_path = ""
    for (i = 1; i <= length(path); i++) {
        c = substr(path, i, 1)
        if (c == "%") {
            hex = substr(path, i+1, 2)
            decoded_path = decoded_path sprintf("%c", strtonum("0x" hex))
            i += 2
        } else {
            decoded_path = decoded_path c
        }
    }
    path = decoded_path

    n = split(path, parts, "/")
    basename = parts[n]

    if (path !~ /'/) {
        if (system("[ -d '" path "' ] 2>/dev/null") == 0) {
            print \$0 "\0display\x1f[Folder] " basename "\x1ficon\x1ffolder"
            next
        } 
        else if (system("[ -f '" path "' ] 2>/dev/null") == 0) {
            icon = "text-x-generic"
            prefix = "[File]"
            lower_base = tolower(basename)
            
            if (lower_base ~ /\.(jpg|jpeg|png|bmp|gif|webp|svg)$/) {
                icon = path
                prefix = "[Image]"
            }
            else if (lower_base ~ /\.(mp4|webm|mkv|mov|avi|flv)$/) {
                icon = "video-x-generic"
                prefix = "[Video]"
            }
            else if (lower_base ~ /\.pdf$/) icon = "application-pdf"
            else if (lower_base ~ /\.(zip|rar|tar|gz|7z)$/) icon = "application-zip"
            else if (lower_base ~ /\.(doc|docx|odt)$/) icon = "x-office-document"
            else if (lower_base ~ /\.(xls|xlsx|ods)$/) icon = "x-office-spreadsheet"
            else if (lower_base ~ /\.(ppt|pptx|odp)$/) icon = "x-office-presentation"
            else if (lower_base ~ /\.(txt|md|log|csv)$/) icon = "text-x-generic"

            print \$0 "\0display\x1f" prefix " " basename "\x1ficon\x1f" icon
            next
        }
    }
}

{
    display_text = \$0
    sub(/^[0-9]+[ \t]+/, "", display_text)
    print \$0 "\0display\x1f" display_text
}
EOF

cliphist list | head -n 500 | gawk "$prog"
