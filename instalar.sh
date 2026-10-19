#!/bin/bash
# xfce-estilo-mac: deja XFCE con el estilo de macOS (barra translucida, dock flotante, Spotlight,
# Launchpad, menu principal, Configuracion del Sistema, iconos y ventanas tipo Mac).
#
# Uso:  ./instalar.sh [--color rojo|azul|verde|violeta|rosa|naranja|amarillo|gris] [--sin-paquetes] [--touchpad]
#   --color         color de acento (por defecto: rojo)
#   --sin-paquetes  no instala programas (si ya los tenes o tu distro no esta soportada)
#   --touchpad      configura el touchpad como en Mac sin preguntar (tocar = clic, deslizamiento natural)
#
# Antes de cambiar nada guarda una copia de tu configuracion en ~/.config/xfce-estilo-mac/respaldo-FECHA
# (para volver atras: ./desinstalar.sh).
set -e
RAIZ=$(cd "$(dirname "$0")" && pwd)
COLOR=rojo; PAQUETES=si; TOUCHPAD=preguntar
while [ $# -gt 0 ]; do
    case "$1" in
        --color) COLOR=$2; shift ;;
        --sin-paquetes) PAQUETES=no ;;
        --touchpad) TOUCHPAD=si ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "Opción desconocida: $1"; exit 1 ;;
    esac
    shift
done

paso(){ printf '\n\033[1;31m==>\033[0m \033[1m%s\033[0m\n' "$1"; }
aviso(){ printf '\033[1;33m   ! %s\033[0m\n' "$1"; }

[ "$(id -u)" != 0 ] || { echo "Corrélo con tu usuario normal, no con sudo (pide la clave cuando hace falta)."; exit 1; }

# color de acento -> variante de WhiteSur y color de los menus
case "$COLOR" in
    rojo)     WS=red;    ACENTO="#E0353F" ;;
    azul)     WS=blue;   ACENTO="#0A84FF" ;;
    verde)    WS=green;  ACENTO="#30B74F" ;;
    violeta)  WS=purple; ACENTO="#A550DA" ;;
    rosa)     WS=pink;   ACENTO="#E8336A" ;;
    naranja)  WS=orange; ACENTO="#F08A00" ;;
    amarillo) WS=yellow; ACENTO="#D4A800" ;;
    gris)     WS=grey;   ACENTO="#6E6E73" ;;
    *) echo "Color desconocido: $COLOR"; exit 1 ;;
esac
# iconos siempre en su version clasica (carpetas celestes, como en Mac); el color de acento va en ventanas y menus
ICONOS_WS=WhiteSur-dark

# ---------------------------------------------------------------------------------------------
paso "1/8 Programas necesarios"
if [ $PAQUETES = si ]; then
    if command -v apt-get >/dev/null; then
        GESTOR=(sudo apt-get install -y)
        LISTA="xfce4-panel xfce4-genmon-plugin xfce4-docklike-plugin xfce4-pulseaudio-plugin xfce4-notifyd
               xfce4-taskmanager thunar rofi fonts-inter fonts-font-awesome fonts-firacode python3-gi python3-gi-cairo
               gir1.2-gtk-3.0 python3-fonttools python3-brotli imagemagick xdotool x11-utils x11-xserver-utils
               xinput sassc git libglib2.0-dev-bin libxml2-utils network-manager libnotify-bin pciutils"
        sudo apt-get update -qq || true
    elif command -v pacman >/dev/null; then
        GESTOR=(sudo pacman -S --needed --noconfirm)
        LISTA="xfce4-panel xfce4-genmon-plugin xfce4-docklike-plugin xfce4-pulseaudio-plugin xfce4-notifyd
               xfce4-taskmanager thunar rofi inter-font ttf-font-awesome ttf-fira-code python-gobject python-cairo
               gtk3 python-fonttools python-brotli imagemagick xdotool xorg-xprop xorg-xrandr xorg-xset
               xorg-xinput sassc git glib2 libxml2 networkmanager libnotify pciutils"
    elif command -v dnf >/dev/null; then
        GESTOR=(sudo dnf install -y)
        LISTA="xfce4-panel xfce4-genmon-plugin xfce4-docklike-plugin xfce4-pulseaudio-plugin xfce4-notifyd
               xfce4-taskmanager Thunar rofi rsms-inter-fonts fontawesome-6-free-fonts fontawesome-6-brands-fonts
               fira-code-fonts python3-gobject python3-cairo gtk3 python3-fonttools python3-brotli ImageMagick
               xdotool xprop xrandr xset xinput sassc git glib2-devel libxml2 NetworkManager libnotify pciutils"
    elif command -v zypper >/dev/null; then
        GESTOR=(sudo zypper --non-interactive install)
        LISTA="xfce4-panel xfce4-panel-plugin-genmon xfce4-panel-plugin-docklike xfce4-panel-plugin-pulseaudio
               xfce4-notifyd xfce4-taskmanager thunar rofi google-inter-fonts fontawesome-fonts fira-code-fonts
               python3-gobject python3-gobject-cairo typelib-1_0-Gtk-3_0 python3-fonttools python3-Brotli
               ImageMagick xdotool xprop xrandr xset xinput sassc git glib2-devel libxml2-tools NetworkManager
               libnotify-tools pciutils"
    else
        aviso "No reconozco el gestor de paquetes. Instalá a mano lo de la sección 'Requisitos' del README y usá --sin-paquetes."
        exit 1
    fi
    # primero todo junto; si algun nombre no existe en esta distro, de a uno (y se avisa cual falto)
    if ! "${GESTOR[@]}" $LISTA; then
        for p in $LISTA; do "${GESTOR[@]}" "$p" >/dev/null 2>&1 || aviso "No se pudo instalar: $p"; done
    fi
fi
for c in xfconf-query xfce4-panel rofi python3 git sassc xdotool xprop xrandr; do
    command -v "$c" >/dev/null || { echo "Falta el programa '$c'. Instalalo y volvé a correr el instalador."; exit 1; }
done
IM=$(command -v magick || command -v convert) || { echo "Falta ImageMagick."; exit 1; }

# letra de iconos: Font Awesome 6 (o 5)
FA=""; for v in 6 5; do fc-list : family | grep -q "Font Awesome $v Free" && { FA="Font Awesome $v Free"; FAV=$v; break; }; done
[ -n "$FA" ] || { echo "Falta la letra Font Awesome (6 o 5)."; exit 1; }
# el archivo de cada variante (el nombre registrado cambia segun la distro); primero .ttf/.otf, despues .woff2
archivo_fa(){ fc-list : file family style | grep -i "Font Awesome $FAV" | grep -i "$1" | cut -d: -f1 | sort -t. -k2 | grep -E '\.(ttf|otf)$' | head -1; }
archivo_fa_cualquiera(){ fc-list : file family style | grep -i "Font Awesome $FAV" | grep -i "$1" | cut -d: -f1 | head -1; }
FA_SOLID=$(archivo_fa solid); [ -n "$FA_SOLID" ] || FA_SOLID=$(archivo_fa_cualquiera solid)
FA_MARCAS=$(archivo_fa brands); [ -n "$FA_MARCAS" ] || FA_MARCAS=$(archivo_fa_cualquiera brands)
[ -n "$FA_SOLID" ] && [ -n "$FA_MARCAS" ] || { echo "No encuentro los archivos de Font Awesome (Solid y Brands)."; exit 1; }
fc-list : family | grep -qx "Inter" || fc-list : family | grep -q "^Inter" || aviso "No encuentro la letra Inter: se va a ver con otra."

# ---------------------------------------------------------------------------------------------
paso "2/8 Copia de seguridad de tu configuración"
RESP=$HOME/.config/xfce-estilo-mac/respaldo-$(date +%Y%m%d-%H%M%S)
mkdir -p "$RESP"
[ -d "$HOME/.config/xfce4" ] && cp -a "$HOME/.config/xfce4" "$RESP/"
[ -f "$HOME/.config/gtk-3.0/gtk.css" ] && cp -a "$HOME/.config/gtk-3.0/gtk.css" "$RESP/"
[ -d "$HOME/.config/rofi" ] && cp -a "$HOME/.config/rofi" "$RESP/"
echo "   Guardada en $RESP"

# ---------------------------------------------------------------------------------------------
paso "3/8 Temas WhiteSur (ventanas, iconos, cursores y fondos estilo Mac)"
CACHE=$HOME/.cache/xfce-estilo-mac; mkdir -p "$CACHE"
bajar(){ # repo
    if [ -d "$CACHE/$1/.git" ]; then git -C "$CACHE/$1" pull -q --ff-only || true
    else git clone -q --depth 1 "https://github.com/vinceliuice/$1.git" "$CACHE/$1"; fi
}
for r in WhiteSur-gtk-theme WhiteSur-icon-theme WhiteSur-cursors WhiteSur-wallpapers; do echo "   $r"; bajar "$r"; done
# al final intenta reiniciar la barra (xfce4-panel -r) y "falla" si no esta corriendo: se ignora,
# lo que importa es que el tema quede instalado (se verifica mas abajo)
( cd "$CACHE/WhiteSur-gtk-theme" && ./install.sh -c dark -t "$WS" -o solid >/dev/null 2>&1 ) || true
rm -f "$HOME/.local/bin/gnome-theme-switcher" "$HOME/.local/share/applications/org.gnome.GTK4ThemeSwitcher.desktop"
( cd "$CACHE/WhiteSur-icon-theme" && ./install.sh >/dev/null ) || true
[ -d "$HOME/.local/share/icons/$ICONOS_WS" ] || { echo "No se instalaron los iconos WhiteSur."; exit 1; }
mkdir -p "$HOME/.icons" && rm -rf "$HOME/.icons/WhiteSur-cursors" && cp -a "$CACHE/WhiteSur-cursors/dist" "$HOME/.icons/WhiteSur-cursors"
TEMA_GTK=$( (ls -d "$HOME/.themes"/WhiteSur-Dark-solid-"$WS" "$HOME/.themes"/WhiteSur-Dark-solid 2>/dev/null || true) | head -1 | xargs -r basename)
[ -n "$TEMA_GTK" ] || { echo "No se instaló el tema WhiteSur."; exit 1; }
FOTOS=$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures"); mkdir -p "$FOTOS/Fondos"
cp -n "$CACHE"/WhiteSur-wallpapers/4k/*.jpg "$FOTOS/Fondos/" 2>/dev/null || true
FONDO=$FOTOS/Fondos/Sonoma-light.jpg

# tamaño de pantalla: en pantallas de mucha resolucion todo un poco mas grande
ANCHO=$(xrandr --current 2>/dev/null | awk '/\*/{split($1,r,"x"); print r[1]; exit}')
if [ "${ANCHO:-0}" -ge 2400 ]; then GRANDE=si; TEMA_XFWM=$TEMA_GTK-xhdpi; else GRANDE=no; TEMA_XFWM=$TEMA_GTK; fi
[ -d "$HOME/.themes/$TEMA_XFWM" ] || TEMA_XFWM=$TEMA_GTK

# ---------------------------------------------------------------------------------------------
paso "4/8 Programitas de la barra, menús y Configuración del Sistema"
poner(){ # origen destino: copia reemplazando las marcas @...@
    mkdir -p "$(dirname "$2")"
    sed -e "s|@HOME@|$HOME|g" -e "s|@FA@|$FA|g" -e "s|@ACENTO@|$ACENTO|g" -e "s|@ICONOS@|$ICONOS_WS|g" "$1" > "$2"
}
for f in "$RAIZ"/archivos/bin/*.sh; do poner "$f" "$HOME/.local/bin/$(basename "$f")"; chmod +x "$HOME/.local/bin/$(basename "$f")"; done
for f in "$RAIZ"/archivos/rofi/*.rasi; do poner "$f" "$HOME/.config/rofi/$(basename "$f")"; done
poner "$RAIZ/archivos/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
poner "$RAIZ/archivos/configuracion/configuracion.py" "$HOME/.local/share/configuracion-mac/configuracion.py"
poner "$RAIZ/archivos/configuracion/configuracion-mac.desktop" "$HOME/.local/share/applications/configuracion-mac.desktop"
poner "$RAIZ/archivos/autostart/ajustes-al-iniciar.desktop" "$HOME/.config/autostart/ajustes-al-iniciar.desktop"
# el programa de red de siempre se reemplaza por el icono de Wi-Fi blanco de la barra
printf '[Desktop Entry]\nType=Application\nName=Network\nExec=nm-applet\nHidden=true\n' > "$HOME/.config/autostart/nm-applet.desktop"

# ---------------------------------------------------------------------------------------------
paso "5/8 Iconos gruesos de la barra y logo del menú"
python3 "$RAIZ/scripts/generar-iconos.py" "$FA_SOLID" "$FA_MARCAS" "$ICONOS_WS"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Mac-Gruesos" >/dev/null 2>&1 || true
if [ $GRANDE = si ]; then LOGO=46x34; else LOGO=30x22; fi
"$IM" -background none -density 600 "$HOME/.local/share/icons/menu-principal.svg" -trim +repage \
    -resize "$LOGO" -channel A -level 0,55% +channel -fill white -colorize 100 \
    -gravity center -extent "$LOGO" +repage "$HOME/.local/share/icons/menu-principal.png"

# ---------------------------------------------------------------------------------------------
paso "6/8 Barra, dock, ventanas, atajos y fondo"
TEMA_GTK=$TEMA_GTK TEMA_XFWM=$TEMA_XFWM CURSORES=WhiteSur-cursors FONDO=$FONDO GRANDE=$GRANDE \
    bash "$RAIZ/scripts/aplicar-xfconf.sh"
pkill -x nm-applet 2>/dev/null || true

# ---------------------------------------------------------------------------------------------
paso "7/8 Firefox estilo Safari"
if [ -d "$HOME/.mozilla/firefox" ] || [ -d "$HOME/.config/mozilla/firefox" ]; then
    bash "$RAIZ/scripts/firefox-estilo-mac.sh" "$CACHE/WhiteSur-gtk-theme"
    echo "   Se ve la próxima vez que abras Firefox."
else
    echo "   No encontré un perfil de Firefox (abrilo una vez y volvé a correr el instalador)."
fi

# ---------------------------------------------------------------------------------------------
paso "8/8 Touchpad estilo Mac (opcional)"
if [ $TOUCHPAD = preguntar ] && [ -t 0 ]; then
    read -r -p "   ¿Configurar el touchpad como en Mac (tocar = clic, dos dedos = clic derecho, deslizamiento natural)? [s/N] " r
    [ "${r,,}" = s ] && TOUCHPAD=si
fi
if [ $TOUCHPAD = si ]; then
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo cp "$RAIZ/archivos/xorg/40-touchpad.conf" /etc/X11/xorg.conf.d/40-touchpad.conf
    echo "   Listo (se aplica del todo al volver a iniciar sesión)."
fi

printf '\n\033[1;32m¡Listo!\033[0m Si algo no se ve bien, cerrá sesión y volvé a entrar.\n'
echo "Atajos: Windows+Espacio = Spotlight · Windows+A = Launchpad · Ctrl+Esc = menú · Windows+flechas = dividir pantalla"
echo "Para volver a como estaba:  $RAIZ/desinstalar.sh"
