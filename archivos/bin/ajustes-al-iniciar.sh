#!/bin/bash
# Se corre al iniciar la sesion:
#  - si la placa de video anda (hay un driver DRM), prende efectos: barras translucidas y redondeadas.
#    Si no (por ejemplo arrancando con nomodeset), los apaga y deja las barras solidas.
#  - centra el dock abajo segun el tamaño de la pantalla.
#  - apaga el protector de pantalla basico de X (ponia la pantalla en negro a los 5 minutos).
q(){ xfconf-query -c xfce4-panel "$@"; }

xset s off s noblank -dpms 2>/dev/null

placa=no
for d in /sys/class/drm/card[0-9]/device/driver; do
    [ -e "$d" ] && placa=si
done
if [ $placa = si ]; then
    # el fondo redondeado y translucido de las barras lo pinta ~/.config/gtk-3.0/gtk.css
    xfconf-query -c xfwm4 -p /general/use_compositing -s true
    xfconf-query -c xfwm4 -p /general/show_dock_shadow -n -t bool -s false   # la sombra del dock es cuadrada
    alfa=0
else
    xfconf-query -c xfwm4 -p /general/use_compositing -s false
    alfa=1
fi
for p in 1 2; do
    q -p /panels/panel-$p/background-style -n -t uint -s 1
    q -p /panels/panel-$p/background-rgba -n -t double -s 0.15 -t double -s 0.15 -t double -s 0.16 -t double -s $alfa
done

# dock flotando, centrado y un poco separado del borde de abajo
read -r ancho alto < <(xrandr --current 2>/dev/null | awk '/\*/{split($1,r,"x"); print r[1], r[2]; exit}')
tam=$(q -p /panels/panel-2/size 2>/dev/null || echo 64)
if [ -n "$ancho" ] && [ -n "$alto" ]; then
    q -p /panels/panel-2/position -n -t string -s "p=0;x=$((ancho / 2));y=$((alto - tam / 2 - tam / 5))"
fi
