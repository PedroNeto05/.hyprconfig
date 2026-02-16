#!/usr/bin/env bash

## Diretório e Tema do Rofi
dir="$HOME/.config/rofi/wifi/type-1"
theme='style-1'
rofi_theme="-theme ${dir}/${theme}.rasi"

while true; do
    # Limpa as variáveis a cada ciclo para não duplicar a lista ao recarregar
    unset menu_map security_map seen_ssids rofi_list connected_ssid
    declare -A menu_map
    declare -A security_map
    declare -A seen_ssids
    rofi_list=()
    connected_ssid=""

    # Tática à prova de falhas: pega o nome da conexão Wi-Fi ativa no sistema ANTES do loop
    active_connection=$(LC_ALL=C nmcli --color no -t -f NAME,TYPE connection show --active | awk -F: '/802-11-wireless/ {print $1}' | head -n 1)

    # Obtém a lista de redes via nmcli (forçando sem cores e padrão C para evitar bugs de caracteres)
    while IFS=: read -r in_use ssid signal security rest; do
        # Pula redes ocultas ou duplicadas
        if [ -z "$ssid" ] || [ -n "${seen_ssids["$ssid"]}" ]; then
            continue
        fi
        seen_ssids["$ssid"]=1
        
        # Verifica se a rede precisa de senha
        is_secure=true
        if [[ "$security" == "--" || -z "$security" ]]; then
            is_secure=false
        fi

        # Define o ícone com base no sinal e na necessidade de senha
        if [ "$is_secure" = true ]; then
            if [ "$signal" -le 25 ]; then icon="󰤡"
            elif [ "$signal" -le 50 ]; then icon="󰤤"
            elif [ "$signal" -le 75 ]; then icon="󰤧"
            else icon="󰤪"
            fi
        else
            if [ "$signal" -le 25 ]; then icon="󱛋"
            elif [ "$signal" -le 50 ]; then icon="󱛌"
            elif [ "$signal" -le 75 ]; then icon="󱛍"
            else icon="󱛎"
            fi
        fi

        status=""
        # NOVA CHECAGEM: Verifica pelo asterisco OU se o nome bate com a conexão ativa garantida
        if [[ "$in_use" == *"*"* ]] || [[ "$ssid" == "$active_connection" ]]; then
            status=" (connected)"
            connected_ssid="$ssid" # Agora temos certeza absoluta de quem está conectado
        fi

        # Linha para o Rofi
        line="$icon  $ssid$status"
        
        # Salva mapeamento
        rofi_list+=("$line")
        menu_map["$line"]="$ssid"
        security_map["$ssid"]="$security"

    done < <(LC_ALL=C nmcli --color no -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list)

    # Se não houver redes, sai silenciosamente
    if [ ${#rofi_list[@]} -eq 0 ]; then
        exit 1
    fi

    # 1. Menu Principal (Escolher Rede)
    chosen_line=$(printf "%s\n" "${rofi_list[@]}" | rofi -dmenu $rofi_theme -theme-str 'inputbar { enabled: false; }' -i -p "Wi-Fi")

    # Sai do script se pressionar Esc
    if [ -z "$chosen_line" ]; then
        exit 0
    fi

    # Recupera dados reais
    ssid="${menu_map["$chosen_line"]}"
    security="${security_map["$ssid"]}"

    # 2. Verifica se a rede já está salva no sistema
    is_known=$(LC_ALL=C nmcli --color no -t -f NAME,TYPE connection show | awk -F: '/802-11-wireless/ {print $1}' | grep -F -x "$ssid")

    # Define opções do submenu baseado na rede conectada
    options=""
    if [ "$ssid" = "$connected_ssid" ]; then
        options="Disconnect\nForget\nBack"
    elif [ -n "$is_known" ]; then
        options="Connect\nForget\nBack"
    else
        options="Connect\nBack"
    fi

    # 3. Submenu de Ação
    action=$(echo -e "$options" | rofi -dmenu $rofi_theme -theme-str 'inputbar { enabled: false; }' -i -p "$ssid")

    # Se apertar Esc no submenu ou escolher Back, reinicia o loop
    if [ -z "$action" ] || [ "$action" = "Back" ]; then
        continue
    fi

    # 4. Executa a ação
    case "$action" in
        "Connect")
            if [ -n "$is_known" ]; then
                # Conecta rede conhecida
                nmcli connection up id "$ssid"
            else
                # Rede nova
                if [[ "$security" == "--" || -z "$security" ]]; then
                    # Rede Aberta
                    nmcli device wifi connect "$ssid"
                else
                    # Rede com Senha
                    password=$(rofi -dmenu $rofi_theme -theme-str 'listview { enabled: false; }' -theme-str 'entry { placeholder: "Type your password..."; }' -password -p "Enter password:")
                    if [ -n "$password" ]; then
                        nmcli device wifi connect "$ssid" password "$password"
                    else
                        continue
                    fi
                fi
            fi
            ;;
        "Disconnect")
            nmcli connection down id "$ssid"
            ;;
        "Forget")
            nmcli connection delete id "$ssid"
            ;;
    esac

done
