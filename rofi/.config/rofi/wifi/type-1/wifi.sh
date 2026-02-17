#!/usr/bin/env bash

## Diretório e Tema do Rofi
dir="$HOME/.config/rofi/wifi/type-1"
theme='style-1'
rofi_theme="-theme ${dir}/${theme}.rasi"

while true; do
    # Limpa as variáveis a cada ciclo para não duplicar a lista ao recarregar
    unset menu_map security_map seen_ssids rofi_list wired_list wifi_list connection_type connected_ssid
    declare -A menu_map
    declare -A security_map
    declare -A seen_ssids
    declare -A connection_type
    rofi_list=()
    wired_list=()
    wifi_list=()
    connected_ssid=""

    # ==========================================
    # 1. VERIFICA CONEXÕES CABEADAS
    # ==========================================
    while IFS=: read -r dev type state con; do
        if [ "$state" != "unavailable" ] && [ "$state" != "unmanaged" ]; then
            if [ "$state" = "connected" ]; then
                line="󰈀  $con (connected)"
                wired_list+=("$line")
                menu_map["$line"]="$con"
                connection_type["$con"]="wired_active"
            else
                line="󰈀  $dev (disconnected)"
                wired_list+=("$line")
                menu_map["$line"]="$dev"
                connection_type["$dev"]="wired_inactive"
            fi
        fi
    done < <(LC_ALL=C nmcli --color no -t -f DEVICE,TYPE,STATE,CONNECTION device status | grep "ethernet")

    # ==========================================
    # 2. VERIFICA CONEXÕES WI-FI
    # ==========================================
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
        wifi_list+=("$line")
        menu_map["$line"]="$ssid"
        security_map["$ssid"]="$security"
        connection_type["$ssid"]="wifi"

    done < <(LC_ALL=C nmcli --color no -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list)

    # ==========================================
    # 3. MONTA A LISTA FINAL
    # ==========================================
    # Adiciona as opções de cabo primeiro
    for w in "${wired_list[@]}"; do
        rofi_list+=("$w")
    done

    # Adiciona as opções de Wi-Fi depois
    for w in "${wifi_list[@]}"; do
        rofi_list+=("$w")
    done

    # Se não houver redes, sai silenciosamente
    if [ ${#rofi_list[@]} -eq 0 ]; then
        exit 1
    fi

    # 4. CHAMA O ROFI (Menu Principal)
    chosen_line=$(printf "%s\n" "${rofi_list[@]}" | rofi -dmenu $rofi_theme -theme-str 'inputbar { enabled: false; }' -i -p "Network")

    # Sai do script se pressionar Esc
    if [ -z "$chosen_line" ]; then
        exit 0
    fi

    # ==========================================
    # 5. DIRECIONA A AÇÃO (CABO OU WI-FI)
    # ==========================================
    # Recupera o nome real e o tipo da rede selecionada
    selected_name="${menu_map["$chosen_line"]}"
    net_type="${connection_type["$selected_name"]}"

    # LÓGICA PARA REDE CABEADA
    if [[ "$net_type" == *"wired"* ]]; then
        options=""
        if [ "$net_type" == "wired_active" ]; then
            options="Disconnect\nBack"
        else
            options="Connect\nBack"
        fi

        action=$(echo -e "$options" | rofi -dmenu $rofi_theme -theme-str 'inputbar { enabled: false; }' -i -p "$selected_name")

        if [ -z "$action" ] || [ "$action" = "Back" ]; then
            continue
        fi

        case "$action" in
            "Connect")
                nmcli device connect "$selected_name"
                ;;
            "Disconnect")
                nmcli connection down id "$selected_name"
                ;;
        esac

    # LÓGICA PARA WI-FI (A mesma de antes)
    elif [ "$net_type" == "wifi" ]; then
        ssid="$selected_name"
        security="${security_map["$ssid"]}"
        is_known=$(LC_ALL=C nmcli --color no -t -f NAME,TYPE connection show | awk -F: '/802-11-wireless/ {print $1}' | grep -F -x "$ssid")

        options=""
        if [ "$ssid" = "$connected_ssid" ]; then
            options="Disconnect\nForget\nBack"
        elif [ -n "$is_known" ]; then
            options="Connect\nForget\nBack"
        else
            options="Connect\nBack"
        fi

        action=$(echo -e "$options" | rofi -dmenu $rofi_theme -theme-str 'inputbar { enabled: false; }' -i -p "$ssid")

        if [ -z "$action" ] || [ "$action" = "Back" ]; then
            continue
        fi

        case "$action" in
            "Connect")
                if [ -n "$is_known" ]; then
                    nmcli connection up id "$ssid"
                else
                    if [[ "$security" == "--" || -z "$security" ]]; then
                        nmcli device wifi connect "$ssid"
                    else
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
    fi
done
