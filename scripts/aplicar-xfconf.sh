#!/bin/bash
# Aplica la configuracion de XFCE (barra, dock, ventanas, letras, atajos y fondo).
# Lo llama instalar.sh con estas variables: TEMA_GTK TEMA_XFWM CURSORES FONDO GRANDE (si/no)
set -e
q(){ xfconf-query -c xfce4-panel "$@"; }
B=$HOME/.local/bin

if [ "$GRANDE" = si ]; then   # pantallas de mucha resolucion (2K, 4K)
    DPI=144; BARRA=46; LETRA=15; ICONOS=34; DOCK=64; CURSOR=32; TITULO=11
else
    DPI=96;  BARRA=32; LETRA=11; ICONOS=22; DOCK=52; CURSOR=24; TITULO=10
fi

echo "   - letras, tema e iconos"
xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$TEMA_GTK"
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s Mac-Gruesos
xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "Inter 11"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -n -t string -s "Fira Code 11"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -n -t string -s "$CURSORES"
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -n -t int -s $CURSOR
xfconf-query -c xsettings -p /Xft/DPI -n -t int -s $DPI
xfconf-query -c xsettings -p /Xft/Antialias -n -t int -s 1
xfconf-query -c xsettings -p /Xft/HintStyle -n -t string -s hintslight
xfconf-query -c xsettings -p /Xft/RGBA -n -t string -s rgb

echo "   - ventanas y Alt+Tab"
w(){ xfconf-query -c xfwm4 -p "/general/$1" -n -t "$2" -s "$3"; }
w theme string "$TEMA_XFWM"
w button_layout string "|HMC"          # botones a la derecha; para tenerlos a la izquierda como Mac: "CHM|"
w title_font string "Inter Semi-Bold $TITULO"
w title_alignment string center
w use_compositing bool true
w show_dock_shadow bool false
w cycle_draw_frame bool false
w cycle_preview bool false
w cycle_tabwin_mode int 0

echo "   - atajos de teclado"
k(){ xfconf-query -c xfce4-keyboard-shortcuts -p "$1" -n -t string -s "$2"; }
k "/commands/custom/<Super>space" "rofi -show drun"
k "/commands/custom/<Super>a" "rofi -show drun -theme $HOME/.config/rofi/launchpad.rasi"
k "/commands/custom/<Primary>Escape" "$B/menu-principal.sh"
k "/xfwm4/custom/<Super>Left" tile_left_key
k "/xfwm4/custom/<Super>Right" tile_right_key
k "/xfwm4/custom/<Super>Up" tile_up_key
k "/xfwm4/custom/<Super>Down" tile_down_key
k "/xfwm4/custom/<Primary><Super>Up" maximize_window_key
k "/xfwm4/custom/<Primary><Super>Down" hide_window_key

echo "   - fondo de pantalla y escritorio limpio"
for m in $(xrandr --listmonitors 2>/dev/null | awk 'NR>1{print $NF}') default; do
    for ws in 0 1 2 3; do
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor$m/workspace$ws/last-image" -n -t string -s "$FONDO"
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor$m/workspace$ws/image-style" -n -t int -s 5
    done
done
xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0

echo "   - Archivos estilo Finder"
th(){ xfconf-query -c thunar -p "$1" -n -t "$2" -s "$3"; }
th /last-menubar-visible bool false
th /last-statusbar-visible bool false
th /last-separator-position int $((BARRA * 6))
th /shortcuts-icon-size string THUNAR_ICON_SIZE_24
th /last-view string ThunarIconView
th /last-icon-view-zoom-level string THUNAR_ZOOM_LEVEL_150_PERCENT
th /misc-folders-first bool true
thunar -q 2>/dev/null || true   # Archivos queda corriendo por detras: se cierra para que lea el estilo nuevo

echo "   - barra de arriba y dock (se rearman de cero)"
xfce4-panel --quit 2>/dev/null || true
timeout 10 bash -c 'while pgrep -x xfce4-panel >/dev/null; do sleep 0.3; done' || pkill -x xfce4-panel || true
q -p /panels -r -R 2>/dev/null || true
q -p /plugins -r -R 2>/dev/null || true
P=$HOME/.config/xfce4/panel
rm -rf "$P"/launcher-3210 "$P"/launcher-3300 "$P"/launcher-3301

plugin(){ q -p "/plugins/plugin-$1" -n -t string -s "$2"; }
prop(){ q -p "/plugins/plugin-$1/$2" -n -t "$3" -s "$4"; }
genmon(){ # id comando cada-cuantos-ms letra
    plugin "$1" genmon
    prop "$1" command string "$2"
    prop "$1" update-period int "$3"
    prop "$1" use-label bool false
    prop "$1" enable-single-row bool true
    prop "$1" font string "$4"
}
lanzador(){ # id nombre icono comando
    plugin "$1" launcher
    mkdir -p "$P/launcher-$1"
    printf '[Desktop Entry]\nType=Application\nName=%s\nIcon=%s\nExec=%s\nTerminal=false\n' "$2" "$3" "$4" > "$P/launcher-$1/$1.desktop"
    q -p "/plugins/plugin-$1/items" -n -t string -s "$1.desktop" -a
}

# barra de arriba: logo | app activa | ... | estadisticas | wifi | volumen | notificaciones | lupa | reloj
genmon 3240 "echo '<img>$HOME/.local/share/icons/menu-principal.png</img><click>$B/menu-principal.sh</click><tooltip>Menú</tooltip>'" 3600000 "Inter $LETRA"
genmon 3200 "$B/app-activa.sh" 700 "Inter Bold $LETRA"
plugin 12 separator; prop 12 expand bool true; prop 12 style uint 0
plugin 14 systray; prop 14 symbolic-icons bool true; prop 14 square-icons bool true; prop 14 size-max uint $((ICONOS + 2))
genmon 3100 "$B/estadisticas-panel.sh" 2000 "Inter Medium $LETRA"
genmon 3250 "$B/wifi-panel.sh" 5000 "Inter $LETRA"
plugin 16 pulseaudio; prop 16 enable-keyboard-shortcuts bool true
plugin 17 notification-plugin
lanzador 3210 "Spotlight" system-search-symbolic "rofi -show drun"
plugin 19 clock
prop 19 digital-layout uint 3
prop 19 digital-time-format string "%a %-d %b  %-H:%M"
prop 19 digital-time-font string "Inter Semi-Bold $LETRA"
# espacio invisible al final: corre aparte y hace que la punta derecha quede recta
genmon 3220 "echo \"<txt><span fgalpha='1'>MMM</span></txt>\"" 3600000 "Inter $LETRA"

# dock: launchpad | apps | separador | papelera
lanzador 3300 "Launchpad" view-app-grid "rofi -show drun -theme $HOME/.config/rofi/launchpad.rasi"
plugin 3000 docklike
plugin 3302 separator; prop 3302 style uint 1
lanzador 3301 "Papelera" user-trash "thunar trash:///"

ids1=(); for i in 3240 3200 12 14 3100 3250 16 17 3210 19 3220; do ids1+=(-t int -s $i); done
ids2=(); for i in 3300 3000 3302 3301; do ids2+=(-t int -s $i); done
q -p /panels -n -t int -s 1 -t int -s 2 -a
q -p /panels/panel-1/position -n -t string -s "p=6;x=0;y=0"
q -p /panels/panel-1/length -n -t double -s 100
q -p /panels/panel-1/position-locked -n -t bool -s true
q -p /panels/panel-1/size -n -t uint -s $BARRA
q -p /panels/panel-1/icon-size -n -t uint -s $ICONOS
q -p /panels/panel-1/plugin-ids -n "${ids1[@]}"
q -p /panels/panel-2/position -n -t string -s "p=10;x=0;y=0"
q -p /panels/panel-2/length -n -t double -s 1
q -p /panels/panel-2/length-adjust -n -t bool -s true
q -p /panels/panel-2/position-locked -n -t bool -s true
q -p /panels/panel-2/size -n -t uint -s $DOCK
q -p /panels/panel-2/icon-size -n -t uint -s 0
q -p /panels/panel-2/autohide-behavior -n -t uint -s 1
q -p /panels/panel-2/plugin-ids -n "${ids2[@]}"

# apps fijadas en el dock (solo las que existan en esta compu)
fijadas=""
for app in thunar firefox firefox-esr org.mozilla.firefox chromium google-chrome \
           xfce4-terminal qterminal org.xfce.mousepad code configuracion-mac; do
    for d in /usr/share/applications "$HOME/.local/share/applications" /var/lib/flatpak/exports/share/applications; do
        if [ -f "$d/$app.desktop" ]; then
            case "$app" in firefox*|org.mozilla.firefox) echo "$fijadas" | grep -q firefox && continue ;; esac
            fijadas="$fijadas$app;"; break
        fi
    done
done
cat > "$P/docklike-3000.rc" <<EOF
[user]
pinned=$fijadas
indicatorStyle=1
inactiveIndicatorStyle=1
indicatorOrientation=1
indicatorColor=rgb(235,235,240)
inactiveColor=rgb(170,170,175)
indicatorColorFromTheme=false
EOF

"$B/ajustes-al-iniciar.sh"
setsid xfce4-panel >/dev/null 2>&1 < /dev/null &
disown
setsid xfwm4 --replace >/dev/null 2>&1 < /dev/null &
disown
xfdesktop --reload 2>/dev/null || true
