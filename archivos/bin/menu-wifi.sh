#!/bin/bash
# Menu de Wi-Fi estilo Mac: lista de redes, conectar (pide la clave si hace falta), prender/apagar.
TEMA=$HOME/.config/rofi/menu-wifi.rasi
if [ "$(nmcli radio wifi)" = enabled ]; then interruptor="Apagar Wi-Fi"; else interruptor="Prender Wi-Fi"; fi
actual=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2)
redes=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan auto 2>/dev/null \
    | awk -F: '$1!="" && !visto[$1]++ {printf "%s%s   %s%%%s\n", ($1==a?"✓ ":"   "), $1, $2, ($3!=""&&$3!="--"?"   (con clave)":"")}' a="$actual")
eleccion=$(printf '%s\n%s\nConfiguración de red…\n' "$interruptor" "$redes" | rofi -dmenu -i -p "" -no-custom -theme "$TEMA")
case "$eleccion" in
    "") exit 0 ;;
    "Apagar Wi-Fi") nmcli radio wifi off ;;
    "Prender Wi-Fi") nmcli radio wifi on ;;
    "Configuración de red…") nm-connection-editor & ;;
    *)
        ssid=$(echo "$eleccion" | sed -E 's/^(✓ |   )//; s/   [0-9]+%.*$//')
        if nmcli -t -f NAME con show | grep -Fxq "$ssid"; then
            nmcli con up id "$ssid" >/dev/null 2>&1 && notify-send -i network-wireless "Wi-Fi" "Conectado a $ssid" || notify-send -i network-error "Wi-Fi" "No se pudo conectar a $ssid"
        else
            if echo "$eleccion" | grep -q "(con clave)"; then
                clave=$(rofi -dmenu -password -p "Clave de $ssid" -theme "$TEMA" -lines 0) || exit 0
                nmcli dev wifi connect "$ssid" password "$clave" >/dev/null 2>&1
            else
                nmcli dev wifi connect "$ssid" >/dev/null 2>&1
            fi && notify-send -i network-wireless "Wi-Fi" "Conectado a $ssid" || notify-send -i network-error "Wi-Fi" "No se pudo conectar a $ssid (¿clave mal?)"
        fi ;;
esac
