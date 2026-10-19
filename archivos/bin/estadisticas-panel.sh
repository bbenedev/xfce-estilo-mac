#!/bin/bash
# Estadisticas para la barra de arriba (complemento genmon): CPU, RAM, temperatura y bateria.
FA="@FA@"
ant=/tmp/estadisticas-panel-$USER
read -r _ u n s i w x y z _ < /proc/stat
total=$((u+n+s+i+w+x+y+z)); ocio=$((i+w))
if [ -f "$ant" ] && read -r t0 o0 < "$ant" && [ $((total-t0)) -gt 0 ]; then
    cpu=$(( 100 * ( (total-t0) - (ocio-o0) ) / (total-t0) ))
else
    cpu=0
fi
echo "$total $ocio" > "$ant"
ram=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f GB",(t-a)/1048576}' /proc/meminfo)

# temperatura del procesador: AMD (k10temp/zenpower), Intel (coretemp) o la general (acpitz)
temp=""
for sensor in k10temp zenpower coretemp acpitz; do
    for h in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$h/name" 2>/dev/null)" = "$sensor" ] && [ -r "$h/temp1_input" ]; then
            temp="$(( $(cat "$h/temp1_input") / 1000 ))°"; break 2
        fi
    done
done

texto="CPU $cpu%    RAM $ram"
[ -n "$temp" ] && texto="$texto    $temp"

# bateria (si hay): icono blanco segun la carga, con rayo si esta enchufada
bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
if [ -n "$bat_dir" ]; then
    bat=$(cat "$bat_dir/capacity" 2>/dev/null)
    if   [ "$bat" -ge 88 ]; then ico='&#xf240;'
    elif [ "$bat" -ge 63 ]; then ico='&#xf241;'
    elif [ "$bat" -ge 38 ]; then ico='&#xf242;'
    elif [ "$bat" -ge 13 ]; then ico='&#xf243;'
    else ico='&#xf244;'; fi
    for ac in /sys/class/power_supply/*; do
        [ "$(cat "$ac/type" 2>/dev/null)" = Mains ] && [ "$(cat "$ac/online" 2>/dev/null)" = 1 ] && ico="$ico &#xf0e7;"
    done
    texto="$texto    <span font_family='$FA' weight='900' size='smaller'>$ico</span>  $bat%"
fi
echo "<txt><span font_family='Inter' weight='medium' foreground='#FFFFFF'>$texto</span></txt>"
echo "<txtclick>xfce4-taskmanager</txtclick>"
echo "<tooltip>Clic: abrir administrador de tareas</tooltip>"
