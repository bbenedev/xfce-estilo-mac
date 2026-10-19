#!/usr/bin/python3
# Configuracion del Sistema estilo Mac: lista con iconos de colores a la izquierda y,
# a la derecha, la pantalla de configuracion de XFCE incrustada (todas aceptan --socket-id).
# Las que no se pueden incrustar (sonido, red, bluetooth, barras) se abren en su propia ventana.
import math
import os
import platform
import subprocess

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango, PangoCairo
import cairo

FA = "Font Awesome 6 Free Solid"
FA_MARCAS = "Font Awesome 6 Brands"
TAM_ICONO = 34

AZUL, VERDE, ROJO, ROSA, NARANJA = "#0A84FF", "#30D158", "#FF453A", "#FF375F", "#FF9F0A"
VIOLETA, CELESTE, GRIS, GRAFITO, INDIGO = "#BF5AF2", "#40C8E0", "#8E8E93", "#3A3A3C", "#5E5CE6"

# (titulo, color, glifo, fuente, comando, se incrusta?)
SECCIONES = [
    [
        ("Wi-Fi", AZUL, "", FA, [os.path.expanduser("~/.local/bin/menu-wifi.sh")], False),
        ("Bluetooth", AZUL, "", FA_MARCAS, ["blueman-manager"], False),
        ("Red", AZUL, "", FA, ["nm-connection-editor"], False),
    ],
    [
        ("Notificaciones", ROJO, "", FA, ["xfce4-notifyd-config"], True),
        ("Sonido", ROSA, "", FA, ["pavucontrol"], False),
    ],
    [
        ("General", GRIS, "", FA, None, True),
        ("Apariencia", GRAFITO, "", FA, ["xfce4-appearance-settings"], True),
        ("Accesibilidad", AZUL, "", FA, ["xfce4-accessibility-settings"], True),
        ("Barras y Dock", GRAFITO, "", FA, ["xfce4-panel", "--preferences"], False),
        ("Pantallas", AZUL, "", FA, ["xfce4-display-settings"], True),
        ("Fondo de pantalla", CELESTE, "", FA, ["xfdesktop-settings"], True),
        ("Protector de pantalla", CELESTE, "", FA, ["xfce4-screensaver-preferences"], True),
        ("Ventanas", INDIGO, "", FA, ["xfwm4-settings"], True),
        ("Ajustes de ventanas", INDIGO, "", FA, ["xfwm4-tweaks-settings"], True),
    ],
    [
        ("Batería", VERDE, "", FA, ["xfce4-power-manager-settings"], True),
    ],
    [
        ("Inicio de sesión", GRIS, "", FA, ["xfce4-session-settings"], True),
    ],
    [
        ("Teclado", GRIS, "", FA, ["xfce4-keyboard-settings"], True),
        ("Trackpad y mouse", GRIS, "", FA, ["xfce4-mouse-settings"], True),
        ("Apps predeterminadas", NARANJA, "", FA, ["xfce4-mime-settings"], True),
    ],
    [
        ("Avanzado", GRAFITO, "", FA, ["xfce4-settings-editor"], True),
    ],
]

CSS = b"""
.barra-lateral { background-color: #232325; }
.barra-lateral list { background-color: transparent; }
.barra-lateral row { border-radius: 8px; margin: 1px 10px; padding: 5px 8px; }
.barra-lateral row:selected { background-color: #3A3A3C; }
.barra-lateral entry { border-radius: 8px; margin: 14px 12px 8px 12px; }
.separador-seccion { margin: 6px 18px; background-color: #3A3A3C; min-height: 1px; }
.titulo-panel { font-size: 20px; font-weight: bold; padding: 16px 24px 8px 24px; }
.nombre-usuario { font-size: 15px; font-weight: bold; }
.subtitulo { color: #8E8E93; }
.tarjeta { background-color: #2C2C2E; border-radius: 12px; padding: 18px 22px; }
.dato { color: #8E8E93; }
"""


def color_rgb(hexa):
    hexa = hexa.lstrip("#")
    return tuple(int(hexa[i:i + 2], 16) / 255 for i in (0, 2, 4))


def icono_mac(color, glifo, fuente, tam=TAM_ICONO):
    """Cuadradito redondeado de color con el dibujo en blanco, como los de Mac."""
    sup = cairo.ImageSurface(cairo.FORMAT_ARGB32, tam, tam)
    cr = cairo.Context(sup)
    r = tam * 0.23
    cr.new_sub_path()
    cr.arc(tam - r, r, r, -math.pi / 2, 0)
    cr.arc(tam - r, tam - r, r, 0, math.pi / 2)
    cr.arc(r, tam - r, r, math.pi / 2, math.pi)
    cr.arc(r, r, r, math.pi, 3 * math.pi / 2)
    cr.close_path()
    cr.set_source_rgb(*color_rgb(color))
    cr.fill()
    capa = PangoCairo.create_layout(cr)
    desc = Pango.FontDescription.from_string(f"{fuente} {tam * 0.36:.1f}")
    desc.set_absolute_size(tam * 0.52 * Pango.SCALE)
    capa.set_font_description(desc)
    capa.set_text(glifo, -1)
    _, logico = capa.get_pixel_extents()
    cr.move_to((tam - logico.width) / 2 - logico.x, (tam - logico.height) / 2 - logico.y)
    cr.set_source_rgb(1, 1, 1)
    PangoCairo.show_layout(cr, capa)
    return Gdk.pixbuf_get_from_surface(sup, 0, 0, tam, tam)


def leer(ruta, defecto=""):
    try:
        with open(ruta) as f:
            return f.read().strip()
    except OSError:
        return defecto


def nombre_usuario():
    import pwd
    gecos = pwd.getpwuid(os.getuid()).pw_gecos.split(",")[0].strip()
    return gecos or os.environ.get("USER", "")


def nombre_sistema():
    try:
        for linea in open("/etc/os-release"):
            if linea.startswith("PRETTY_NAME="):
                return linea.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    return "Linux"


def placas_de_video():
    try:
        salida = subprocess.run(["lspci"], capture_output=True, text=True).stdout
    except OSError:
        return ""
    placas = []
    for linea in salida.splitlines():
        if any(t in linea for t in ("VGA", "3D controller", "Display controller")):
            nombre = linea.split(": ", 1)[1]
            nombre = nombre.replace("Advanced Micro Devices, Inc. [AMD/ATI]", "AMD").replace("Corporation ", "")
            placas.append(nombre.split(" (rev")[0])
    return " + ".join(placas)


class Configuracion(Gtk.Window):
    def __init__(self):
        super().__init__(title="Configuración del Sistema")
        self.set_default_size(1500, 1000)
        self.set_icon_name("preferences-system")
        self.proceso = None
        self.socket = None

        estilo = Gtk.CssProvider()
        estilo.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), estilo, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        caja = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.add(caja)

        # --- barra lateral ---
        lateral = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        lateral.get_style_context().add_class("barra-lateral")
        lateral.set_size_request(340, -1)
        caja.pack_start(lateral, False, False, 0)

        self.buscador = Gtk.SearchEntry(placeholder_text="Buscar")
        self.buscador.connect("search-changed", lambda *_: self.lista.invalidate_filter())
        lateral.pack_start(self.buscador, False, False, 0)

        desplazable = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER)
        lateral.pack_start(desplazable, True, True, 0)
        self.lista = Gtk.ListBox(selection_mode=Gtk.SelectionMode.SINGLE)
        self.lista.set_filter_func(self.filtrar)
        self.lista.set_header_func(self.encabezado)
        self.lista.connect("row-selected", self.elegido)
        desplazable.add(self.lista)

        self.lista.add(self.fila_usuario())
        for n, seccion in enumerate(SECCIONES):
            for titulo, color, glifo, fuente, comando, incrustar in seccion:
                fila = Gtk.ListBoxRow()
                fila.datos = (titulo, comando, incrustar)
                fila.seccion = n
                h = Gtk.Box(spacing=12)
                h.pack_start(Gtk.Image.new_from_pixbuf(icono_mac(color, glifo, fuente)), False, False, 0)
                h.pack_start(Gtk.Label(label=titulo, xalign=0), True, True, 0)
                fila.add(h)
                self.lista.add(fila)

        # --- lado derecho ---
        derecha = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        caja.pack_start(derecha, True, True, 0)
        self.titulo = Gtk.Label(xalign=0)
        self.titulo.get_style_context().add_class("titulo-panel")
        derecha.pack_start(self.titulo, False, False, 0)
        self.contenido = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        derecha.pack_start(self.contenido, True, True, 0)

        self.connect("destroy", self.salir)
        self.show_all()
        self.lista.select_row(self.lista.get_row_at_index(0))   # arranca en General, como en Mac

    def fila_usuario(self):
        fila = Gtk.ListBoxRow()
        fila.datos = ("General", None, True)
        fila.seccion = -1
        h = Gtk.Box(spacing=12, margin_top=6, margin_bottom=6)
        foto = None
        if os.path.exists(os.path.expanduser("~/.face")):
            try:
                foto = Gtk.Image.new_from_pixbuf(
                    GdkPixbuf.Pixbuf.new_from_file_at_scale(
                        os.path.expanduser("~/.face"), 52, 52, True))
            except GLib.Error:
                foto = None
        h.pack_start(foto or Gtk.Image.new_from_pixbuf(icono_mac(GRIS, "", FA, 52)), False, False, 0)
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, valign=Gtk.Align.CENTER)
        nombre = Gtk.Label(label=nombre_usuario(), xalign=0)
        nombre.get_style_context().add_class("nombre-usuario")
        sub = Gtk.Label(label=nombre_sistema(), xalign=0)
        sub.get_style_context().add_class("subtitulo")
        v.pack_start(nombre, False, False, 0)
        v.pack_start(sub, False, False, 0)
        h.pack_start(v, True, True, 0)
        fila.add(h)
        return fila

    def encabezado(self, fila, anterior):
        if anterior is not None and fila.seccion != anterior.seccion:
            sep = Gtk.Separator()
            sep.get_style_context().add_class("separador-seccion")
            fila.set_header(sep)
        else:
            fila.set_header(None)

    def filtrar(self, fila):
        texto = self.buscador.get_text().strip().lower()
        return not texto or texto in fila.datos[0].lower()

    def cerrar_incrustado(self):
        if self.proceso and self.proceso.poll() is None:
            self.proceso.terminate()
        self.proceso = None
        for hijo in self.contenido.get_children():
            self.contenido.remove(hijo)
            hijo.destroy()
        self.socket = None

    def elegido(self, _lista, fila):
        if fila is None:
            return
        titulo, comando, incrustar = fila.datos
        self.titulo.set_text(titulo)
        self.cerrar_incrustado()
        if comando is None:
            self.contenido.pack_start(self.pagina_general(), True, True, 0)
        elif incrustar:
            self.socket = Gtk.Socket()
            self.socket.connect("plug-removed", lambda *_: True)
            self.contenido.pack_start(self.socket, True, True, 0)
            self.socket.show()
            self.socket.realize()
            self.proceso = subprocess.Popen(comando + [f"--socket-id={self.socket.get_id()}"])
        else:
            self.contenido.pack_start(self.pagina_externa(titulo, comando), True, True, 0)
            subprocess.Popen(comando)
        self.contenido.show_all()

    def pagina_externa(self, titulo, comando):
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14, margin=24, valign=Gtk.Align.START)
        texto = Gtk.Label(label=f"{titulo} se abre en su propia ventana.", xalign=0)
        texto.get_style_context().add_class("subtitulo")
        boton = Gtk.Button(label=f"Abrir {titulo} de nuevo", halign=Gtk.Align.START)
        boton.connect("clicked", lambda *_: subprocess.Popen(comando))
        v.pack_start(texto, False, False, 0)
        v.pack_start(boton, False, False, 0)
        return v

    def pagina_general(self):
        modelo = leer("/sys/class/dmi/id/product_version")
        if not modelo or modelo == "None":
            modelo = leer("/sys/class/dmi/id/product_name")
        marca = leer("/sys/class/dmi/id/sys_vendor")
        cpu = ""
        for linea in open("/proc/cpuinfo"):
            if linea.startswith("model name"):
                cpu = linea.split(":", 1)[1].split(" w/")[0].strip()
                break
        ram = 0
        for linea in open("/proc/meminfo"):
            if linea.startswith("MemTotal"):
                ram = round(int(linea.split()[1]) / 1048576)
        so = nombre_sistema()
        uso = os.statvfs("/")
        total = uso.f_blocks * uso.f_frsize / 1e9
        libre = uso.f_bavail * uso.f_frsize / 1e9
        datos = [
            ("Nombre", f"{marca} {modelo}".strip()),
            ("Procesador", cpu),
            ("Gráficos", placas_de_video()),
            ("Memoria", f"{ram} GB"),
            ("Disco", f"{total - libre:.0f} GB usados de {total:.0f} GB"),
            ("Sistema", so),
            ("Kernel", platform.release()),
        ]
        tarjeta = Gtk.Grid(column_spacing=40, row_spacing=12, margin=24, valign=Gtk.Align.START)
        tarjeta.get_style_context().add_class("tarjeta")
        for i, (clave, valor) in enumerate(datos):
            c = Gtk.Label(label=clave, xalign=0)
            c.get_style_context().add_class("dato")
            tarjeta.attach(c, 0, i, 1, 1)
            tarjeta.attach(Gtk.Label(label=valor, xalign=0, selectable=True), 1, i, 1, 1)
        return tarjeta

    def salir(self, *_):
        self.cerrar_incrustado()
        Gtk.main_quit()


if __name__ == "__main__":
    Configuracion()
    Gtk.main()
