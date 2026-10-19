#!/usr/bin/python3
# Genera dos cosas a partir de la letra Font Awesome (Solid):
#  1. El mini-tema de iconos "Mac-Gruesos": volumen, campana y lupa gruesos para la barra
#     (todo lo demas lo hereda del tema WhiteSur).
#  2. El logo blanco del menu principal (arriba a la izquierda), segun la distro.
# Uso: generar-iconos.py <archivo-font-awesome-solid> <archivo-font-awesome-brands> <tema-que-hereda>
import os
import sys

from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen

solid, marcas, hereda = sys.argv[1], sys.argv[2], sys.argv[3]
destino = os.path.expanduser("~/.local/share/icons/Mac-Gruesos")
os.makedirs(f"{destino}/symbolic", exist_ok=True)

with open(f"{destino}/index.theme", "w") as f:
    f.write(f"""[Icon Theme]
Name=Mac-Gruesos
Comment=Iconos gruesos (Font Awesome) para la barra; el resto lo hereda de {hereda}
Inherits={hereda},hicolor
Directories=symbolic

[symbolic]
Size=16
MinSize=8
MaxSize=512
Type=Scalable
Context=Status
""")


def svg_de_glifo(fuente, codigo, color="#bebebe", ocupa=0.82):
    """Dibujo SVG cuadrado de 16x16 con el glifo centrado."""
    font = TTFont(fuente)
    glifos = font.getGlyphSet()
    g = glifos[font.getBestCmap()[codigo]]
    bp = BoundsPen(glifos)
    g.draw(bp)
    x0, y0, x1, y1 = bp.bounds
    pen = SVGPathPen(glifos)
    g.draw(pen)
    lado = max(x1 - x0, y1 - y0) / ocupa
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    # la letra tiene el eje Y para arriba y el SVG para abajo: se invierte
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
            f'<g transform="translate(8 8) scale({16 / lado:.6f} {-16 / lado:.6f}) translate({-cx} {-cy})">'
            f'<path fill="{color}" d="{pen.getCommands()}"/></g></svg>\n')


ICONOS = {
    0xf028: ["audio-volume-high-symbolic"],
    0xf027: ["audio-volume-medium-symbolic", "audio-volume-low-symbolic"],
    0xf6a9: ["audio-volume-muted-symbolic"],
    0xf0f3: ["notification-symbolic", "notifications-symbolic", "notification-new-symbolic",
             "notifications-new-symbolic"],
    0xf1f6: ["notification-disabled-symbolic", "notifications-disabled-symbolic",
             "notification-disabled-new-symbolic", "notifications-disabled-new-symbolic",
             "notification-new-disabled-symbolic", "notifications-new-disabled-symbolic"],
    0xf002: ["system-search-symbolic", "edit-find-symbolic"],
}
for codigo, nombres in ICONOS.items():
    svg = svg_de_glifo(solid, codigo)
    for n in nombres:
        with open(f"{destino}/symbolic/{n}.svg", "w") as f:
            f.write(svg)

# Logo del menu principal: el de la distro si Font Awesome lo tiene; si no, el pinguino.
distro = ""
try:
    for linea in open("/etc/os-release"):
        if linea.startswith("ID="):
            distro = linea.split("=", 1)[1].strip().strip('"')
except OSError:
    pass
LOGOS = {"ubuntu": 0xf7df, "fedora": 0xf798, "debian": 0xe60b, "centos": 0xf789,
         "opensuse-tumbleweed": 0xf7d6, "opensuse-leap": 0xf7d6, "rhel": 0xf7bc, "linuxmint": 0xf17c}
logo = os.path.expanduser("~/.local/share/icons/menu-principal.svg")
dragon = "/usr/share/kali-defaults/web/images/kali-dragon-icon.svg"
if distro == "kali" and os.path.exists(dragon):
    # Kali: el dragon en blanco, sin el fondo azul ni el circulo
    import re
    t = open(dragon).read()
    t = re.sub(r"<circle[^>]*/>", "", t)
    t = re.sub(r'<path d="m(407\.61 259\.3|282\.31 137\.34)a[^>]*/>', "", t)
    t = t.replace('fill="#153f86"', 'fill="none"')
    open(logo, "w").write(t)
else:
    try:
        svg = svg_de_glifo(marcas, LOGOS.get(distro, 0xf17c), color="#ffffff", ocupa=0.9)
    except KeyError:  # esta version de Font Awesome no trae el logo de la distro
        svg = svg_de_glifo(marcas, 0xf17c, color="#ffffff", ocupa=0.9)
    open(logo, "w").write(svg)
print("iconos y logo listos")
