#!/bin/bash
# Menu del logo (arriba a la izquierda), como el de la manzanita de Mac.
TEMA=$HOME/.config/rofi/menu-principal.rasi
CONF=$HOME/.config/rofi/confirmar.rasi
nombre=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
[ -z "$nombre" ] && nombre=$USER

confirmar() { # pregunta antes de reiniciar, apagar o cerrar sesion
    [ "$(printf 'Cancelar\n%s' "$1" | rofi -dmenu -i -p "" -mesg "¿Seguro que querés $2?" -theme "$CONF")" = "$1" ]
}

acerca() {
    marca=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
    modelo=$(cat /sys/class/dmi/id/product_version 2>/dev/null)
    [ -z "$modelo" ] || [ "$modelo" = "None" ] && modelo=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    cpu=$(lscpu | sed -n 's/^Model name:[[:space:]]*//p' | sed 's/ w\/.*//' | head -1)
    graficos=$(lspci 2>/dev/null | grep -E "VGA|3D|Display" | sed -E 's/.*: //; s/ \(rev [0-9a-f]+\)//; s/Corporation //; s/Advanced Micro Devices, Inc. \[AMD\/ATI\]/AMD/' | paste -sd '+' | sed 's/+/ + /g')
    ram=$(awk '/MemTotal/{printf "%.0f GB", $2/1048576}' /proc/meminfo)
    sistema=$(. /etc/os-release; echo "$PRETTY_NAME")
    usado=$(df -h --output=used,size / | tail -1 | awk '{print $1" de "$2}')
    g="<span foreground='#8E8E93'>"
    rofi -e "<span size='x-large' weight='bold'>$marca $modelo</span>

${g}Procesador</span>   $cpu
${g}Gráficos</span>   $graficos
${g}Memoria</span>   $ram
${g}Disco</span>   $usado usados
${g}Sistema</span>   $sistema
 " -markup -theme "$HOME/.config/rofi/acerca.rasi"
}

opcion=$(printf '%s\n' \
    "Acerca de esta compu" \
    "Configuración del sistema…" \
    "Launchpad" \
    "Forzar salida…" \
    "Reposo" \
    "Reiniciar…" \
    "Apagar…" \
    "Bloquear pantalla" \
    "Cerrar sesión de $nombre…" \
    | rofi -dmenu -i -p "" -no-custom -theme "$TEMA")

case "$opcion" in
    "Acerca de esta compu") acerca ;;
    "Configuración del sistema…") python3 "$HOME/.local/share/configuracion-mac/configuracion.py" & ;;
    "Launchpad") rofi -show drun -theme "$HOME/.config/rofi/launchpad.rasi" ;;
    "Forzar salida…") xfce4-taskmanager & ;;
    "Reposo") systemctl suspend ;;
    "Reiniciar…") confirmar "Reiniciar" "reiniciar la compu" && xfce4-session-logout --reboot --fast ;;
    "Apagar…") confirmar "Apagar" "apagar la compu" && xfce4-session-logout --halt --fast ;;
    "Bloquear pantalla") xflock4 ;;
    "Cerrar sesión de $nombre…") confirmar "Cerrar sesión" "cerrar la sesión" && xfce4-session-logout --logout --fast ;;
esac
