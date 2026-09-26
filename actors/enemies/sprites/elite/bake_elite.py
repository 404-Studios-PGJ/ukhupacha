"""Prepara las hojas del jefe final (robot, vista lateral mirando a la derecha,
frames de 96x96): cambia el verde por rojo, arma la hoja del salto aplastante
(Jump + Fall) y la del golpe rojo frontal. También deja las hojas de los
robots pequeños con el verde original.

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sprites/elite/bake_elite.py "<carpeta del robot>"
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
# Hoja del paquete -> nombre en el proyecto.
SHEETS = {
    "Idle.png": "elite_idle.png",
    "Walk.png": "elite_walk.png",
    "Attack.png": "elite_attack_white.png",
    "Attack3.png": "elite_alert.png",
    "Hurt.png": "elite_hurt.png",
    "Death.png": "elite_death.png",
}
# Salto: Jump (impulso y despegue) seguido de Fall (en el aire e impacto).
LEAP_PARTS = ("Jump.png", "Fall.png")
LEAP_NAME = "elite_leap.png"
# Golpe rojo: la estocada frontal a ras de suelo (frames 1-3 de Attack) con
# la hoja en rojo. Solo se tiñe delante del cuerpo, donde está la hoja.
RED_FROM = "Attack.png"
RED_NAME = "elite_attack_red.png"
BLADE_COLORS = {(204, 226, 225), (255, 255, 255)}
BLADE_FROM_X = 50
BLADE_RED = (255, 64, 56)
FRAME = 96

# Robots pequeños: las mismas animaciones con el verde original.
MINION_SHEETS = {
    "Idle.png": "minion_idle.png",
    "Walk.png": "minion_walk.png",
    "Attack.png": "minion_attack.png",
    "Attack3.png": "minion_alert.png",
    "Hurt.png": "minion_hurt.png",
    "Death.png": "minion_death.png",
}

# Verde del robot -> rojo (oscuro, medio y claro del cristal).
GREEN_TO_RED = {
    (21, 137, 104): (140, 22, 34),
    (70, 198, 87): (214, 46, 54),
    (201, 236, 133): (255, 152, 140),
}


def recolor(image):
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a and (r, g, b) in GREEN_TO_RED:
                pixels[x, y] = (*GREEN_TO_RED[(r, g, b)], a)
    return image


def redden_blade(image):
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a and x % FRAME >= BLADE_FROM_X and (r, g, b) in BLADE_COLORS:
                pixels[x, y] = (*BLADE_RED, a)
    return image


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[4]
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "estilos" / "jefe final" / "3"
    for name, out in SHEETS.items():
        recolor(Image.open(src / name).convert("RGBA")).save(OUT / out)
    redden_blade(recolor(Image.open(src / RED_FROM).convert("RGBA"))).save(OUT / RED_NAME)
    for name, out in MINION_SHEETS.items():
        Image.open(src / name).convert("RGBA").save(OUT / out)
    parts = [recolor(Image.open(src / name).convert("RGBA")) for name in LEAP_PARTS]
    leap = Image.new("RGBA", (sum(p.width for p in parts), parts[0].height))
    x = 0
    for part in parts:
        leap.paste(part, (x, 0))
        x += part.width
    leap.save(OUT / LEAP_NAME)
    print(", ".join(sorted(list(SHEETS.values()) + list(MINION_SHEETS.values())
                           + [LEAP_NAME, RED_NAME])))
