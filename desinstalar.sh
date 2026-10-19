#!/bin/bash
# Vuelve XFCE a como estaba antes de instalar xfce-estilo-mac, usando la ultima copia de seguridad.
# Los temas WhiteSur y los fondos quedan instalados (no molestan); se pueden borrar a mano de
# ~/.themes, ~/.local/share/icons, ~/.icons y la carpeta de Imagenes/Fondos.
set -e
RESP=$(ls -d "$HOME"/.config/xfce-estilo-mac/respaldo-* 2>/dev/null | sort | tail -1)
[ -n "$RESP" ] || { echo "No encontré ninguna copia de seguridad en ~/.config/xfce-estilo-mac."; exit 1; }
echo "Restaurando la copia $RESP ..."

xfce4-panel --quit 2>/dev/null || true
timeout 10 bash -c 'while pgrep -x xfce4-panel >/dev/null; do sleep 0.3; done' || true
pkill -x xfconfd 2>/dev/null || true   # para que no pise los archivos que se restauran

if [ -d "$RESP/xfce4" ]; then rm -rf "$HOME/.config/xfce4" && cp -a "$RESP/xfce4" "$HOME/.config/xfce4"; fi
if [ -f "$RESP/gtk.css" ]; then cp -a "$RESP/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"; else rm -f "$HOME/.config/gtk-3.0/gtk.css"; fi
if [ -d "$RESP/rofi" ]; then rm -rf "$HOME/.config/rofi" && cp -a "$RESP/rofi" "$HOME/.config/rofi"; else rm -rf "$HOME/.config/rofi"; fi

rm -f "$HOME"/.local/bin/{app-activa,estadisticas-panel,wifi-panel,menu-wifi,menu-principal,ajustes-al-iniciar}.sh
rm -f "$HOME/.config/autostart/ajustes-al-iniciar.desktop" "$HOME/.config/autostart/nm-applet.desktop"
rm -f "$HOME/.local/share/applications/configuracion-mac.desktop"
rm -rf "$HOME/.local/share/configuracion-mac" "$HOME/.local/share/icons/Mac-Gruesos"
rm -f "$HOME"/.local/share/icons/menu-principal.{svg,png}

setsid xfce4-panel >/dev/null 2>&1 < /dev/null & disown
setsid xfwm4 --replace >/dev/null 2>&1 < /dev/null & disown
setsid nm-applet >/dev/null 2>&1 < /dev/null & disown
echo "Listo. Cerrá sesión y volvé a entrar para que todo quede como antes."
echo "(Si configuraste el touchpad: sudo rm /etc/X11/xorg.conf.d/40-touchpad.conf)"
