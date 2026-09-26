"""Prepara las hojas del enemigo pesado (Cyborg de estilos/3, vista lateral
mirando a la derecha, frames de 48x48) y le pone la pistola en la mano.

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sprites/cyborg/bake_cyborg.py "<carpeta del Cyborg>"

Asset: "3 Cyborg" de Craftpix (https://craftpix.net/file-licenses/).
Pistola: estilos/armas/Police officer/Weapons.png, reducida.
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
FRAME = 48
# Hoja del paquete -> nombre en el proyecto.
SHEETS = {
    "Cyborg_idle.png": "cyborg_idle.png",
    "Cyborg_run.png": "cyborg_run.png",
    "Cyborg_attack1.png": "cyborg_jab.png",
    "Cyborg_punch.png": "cyborg_kick.png",
    "Cyborg_attack3.png": "cyborg_cannon.png",
    "Cyborg_hurt.png": "cyborg_hurt.png",
    "Cyborg_death.png": "cyborg_death.png",
}
# Silueta de daño (frame 1 de hurt): de rojo a blanco, para no confundirla
# con un ataque rojo.
HURT_SILHOUETTE = (240, 240, 244)
# Cañón de energía: su haz y sus anillos blancos pasan a rojo (ataque rojo).
CANNON_NAME = "Cyborg_attack3.png"
CANNON_RED = (255, 64, 56)
# Disparo: el jab con la pistola en el puño en los frames de brazo extendido.
SHOOT_FROM = "Cyborg_attack1.png"
SHOOT_NAME = "cyborg_shoot.png"
FIST = {4: (27, 23)}  # frame: empuñadura (x, y) dentro del frame

PISTOL_COLORS = {"K": (0, 0, 0), "B": (39, 39, 39), "H": (62, 62, 62)}
# Pistola apuntando a la derecha; "g" es la empuñadura.
PISTOL = (
    "KKKKKKKKK.",
    "KHHHHHHHHK",
    "KBBBBBBBBK",
    ".KBgKKKKK.",
    ".KBBK.....",
    ".KBBK.....",
    "..KK......",
)


def draw_pistol(sheet, frame, fist):
    pixels = sheet.load()
    grip = next((x, y) for y, row in enumerate(PISTOL) for x, c in enumerate(row) if c == "g")
    for y, row in enumerate(PISTOL):
        for x, c in enumerate(row):
            if c == ".":
                continue
            px = frame * FRAME + fist[0] + x - grip[0]
            py = fist[1] + y - grip[1]
            pixels[px, py] = (*PISTOL_COLORS["B" if c == "g" else c], 255)


def redden_blast(sheet):
    pixels = sheet.load()
    for y in range(sheet.height):
        for x in range(sheet.width):
            r, g, b, a = pixels[x, y]
            if a and min(r, g, b) > 230:
                pixels[x, y] = (*CANNON_RED, a)


def whiten_silhouette(sheet):
    pixels = sheet.load()
    for y in range(FRAME):
        for x in range(FRAME, 2 * FRAME):
            r, g, b, a = pixels[x, y]
            if a and r > 150 and g < 90:
                pixels[x, y] = (*HURT_SILHOUETTE, a)


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[4]
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "estilos" / "3" / "3 Cyborg"
    for name, out in SHEETS.items():
        sheet = Image.open(src / name).convert("RGBA")
        if name == "Cyborg_hurt.png":
            whiten_silhouette(sheet)
        if name == CANNON_NAME:
            redden_blast(sheet)
        sheet.save(OUT / out)
    shoot = Image.open(src / SHOOT_FROM).convert("RGBA")
    for frame, fist in FIST.items():
        draw_pistol(shoot, frame, fist)
    shoot.save(OUT / SHOOT_NAME)
    print(", ".join(sorted(list(SHEETS.values()) + [SHOOT_NAME])))
