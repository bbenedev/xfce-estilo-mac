#!/bin/bash
# Tema WhiteSur para Firefox (pestañas y barras estilo Safari), instalado a mano y con cuidado:
# a diferencia de "tweaks.sh -f" de WhiteSur, NO cierra Firefox ni borra tu user.js (solo agrega lineas).
# Se ve la proxima vez que abras Firefox.
# Uso: firefox-estilo-mac.sh <carpeta-de-WhiteSur-gtk-theme>
set -e
SRC=$1/other/firefox
[ -d "$SRC" ] || { echo "No encuentro $SRC"; exit 1; }
for base in "$HOME/.mozilla/firefox" "$HOME/.config/mozilla/firefox"; do
    [ -d "$base" ] || continue
    TEMA=$base/firefox-themes
    rm -rf "$TEMA" && mkdir -p "$TEMA"
    cp -r "$SRC/WhiteSur" "$SRC/customChrome.css" "$TEMA/"
    cp -r "$SRC"/common/{icons,pages,titlebuttons} "$TEMA/WhiteSur/"
    cp "$SRC"/common/*.css "$TEMA/WhiteSur/"
    mkdir -p "$TEMA/WhiteSur/parts" && cp "$SRC"/common/parts/*.css "$TEMA/WhiteSur/parts/"
    cp "$SRC/userChrome-WhiteSur.css" "$TEMA/userChrome.css"
    cp "$SRC/userContent-WhiteSur.css" "$TEMA/userContent.css"
    for perfil in "$base"/*default*; do
        [ -d "$perfil" ] || continue
        if [ -e "$perfil/chrome" ] && [ ! -L "$perfil/chrome" ]; then
            mv "$perfil/chrome" "$perfil/chrome.antes-de-estilo-mac-$(date +%Y%m%d%H%M%S)"
        fi
        ln -sfn "$TEMA" "$perfil/chrome"
        for pref in \
            'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
            'user_pref("browser.tabs.drawInTitlebar", true);' \
            'user_pref("browser.uidensity", 0);' \
            'user_pref("svg.context-properties.content.enabled", true);' \
            'user_pref("widget.gtk.rounded-bottom-corners.enabled", true);'; do
            grep -qxF "$pref" "$perfil/user.js" 2>/dev/null || echo "$pref" >> "$perfil/user.js"
        done
        echo "   Firefox: $(basename "$perfil")"
    done
done
