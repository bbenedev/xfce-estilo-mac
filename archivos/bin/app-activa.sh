#!/bin/bash
# Nombre de la app activa en negrita, como en la barra de Mac (complemento genmon).
id=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $NF}')
clase=""
if [ -n "$id" ] && [ "$id" != "0x0" ]; then
    clase=$(xprop -id "$id" WM_CLASS 2>/dev/null | awk -F'"' '{print $4}')
fi
case "${clase,,}" in
    ""|xfdesktop|xfce4-panel|wrapper-2.0) nombre="Escritorio" ;;
    qterminal|xfce4-terminal|gnome-terminal*|konsole|alacritty|kitty|tilix|terminator|wezterm*) nombre="Terminal" ;;
    firefox*|navigator|librewolf) nombre="Firefox" ;;
    chromium*|google-chrome*|brave*) nombre="${clase^}" ;;
    thunar|nautilus|nemo|pcmanfm*|dolphin) nombre="Archivos" ;;
    mousepad|gedit|gnome-text-editor|kate|featherpad) nombre="Editor de texto" ;;
    code|code-oss|vscodium) nombre="Visual Studio Code" ;;
    xfce4-taskmanager) nombre="Administrador de tareas" ;;
    xfce4-settings-manager|configuracion.py) nombre="Configuración" ;;
    rofi) exit 0 ;;
    *) nombre="${clase^}" ;;
esac
echo "<txt><span font_family='Inter' weight='bold' foreground='#FFFFFF'>$nombre</span></txt>"
