#!/usr/bin/env bash

tmp_dir="/tmp/cliphist"
rm -rf "$tmp_dir"

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
            
            if [[ "$mime_type" == image/* ]]; then
                wl-copy --type "$mime_type" < "$filepath"
                exit
            fi
        fi
    fi

    cliphist decode <<<"$1" | wl-copy
    exit
fi

mkdir -p "$tmp_dir"

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }

match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0"\0icon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}

match(\$0, /^([0-9]+)\s+file:\/\/(.*(jpg|jpeg|png|bmp|gif|webp))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    gsub(/%20/, " ", path)
    print \$0"\0icon\x1f"path
    next
}

match(\$0, /^([0-9]+)\s+(\/.*(jpg|jpeg|png|bmp|gif|webp))/, grp) {
    path = grp[2]
    gsub(/[\r\n]/, "", path)
    print \$0"\0icon\x1f"path
    next
}

1
EOF

cliphist list | gawk "$prog"
