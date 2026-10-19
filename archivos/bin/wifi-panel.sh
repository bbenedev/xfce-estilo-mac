#!/bin/bash
# Icono de Wi-Fi blanco para la barra (complemento genmon); al tocarlo abre el menu de redes.
command -v nmcli >/dev/null || exit 0
fa="font_family='@FA@' weight='900'"
red=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes:' | head -1)
if [ -n "$red" ]; then
    ssid=$(echo "$red" | cut -d: -f2); senal=$(echo "$red" | cut -d: -f3)
    echo "<txt>  <span $fa foreground='#FFFFFF'>&#xf1eb;</span> </txt>"
    echo "<tooltip>Conectado a $ssid ($senal%)</tooltip>"
else
    echo "<txt>  <span $fa foreground='#FFFFFF' alpha='35%'>&#xf1eb;</span> </txt>"
    echo "<tooltip>Sin Wi-Fi</tooltip>"
fi
echo "<txtclick>$HOME/.local/bin/menu-wifi.sh</txtclick>"
