"""Genera las hojas del enemigo ligero (oficinista) a partir del personaje de
estilos/1: recolorea la ropa y junta las 6 direcciones en una hoja por
animación.

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sprites/office/bake_office.py "<carpeta estilos/1>"

Cada hoja sale de 384x384: 8 columnas (frames de 48x64) y 6 filas en este
orden: abajo, derecha-abajo, derecha-arriba, arriba, izquierda-arriba,
izquierda-abajo.
"""
import colorsys
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
DIRECTIONS = ("down", "right_down", "right_up", "up", "left_up", "left_down")
# Filas donde se le ve el pecho (y por lo tanto la corbata).
FRONT_ROWS = (0, 1, 5)
# Animación: (carpeta, prefijo de archivo). Los nombres del paquete mezclan
# mayúsculas, así que se buscan sin distinguirlas.
ANIMATIONS = {
    "idle": ("Idle", "idle"),
    "walk": ("Walk", "walk"),
    "dash": ("Dash", "dash"),
    "jump": ("Jump - NEW/Normal", "jump"),
    "death": ("Death", "death_normal"),
}

# Paletas de oficina (de oscuro a claro) por grupo de color.
LOOKS = {
    "a": {  # camisa blanca, pantalón carbón, pelo castaño, corbata roja
        "shirt": [(150, 158, 176), (196, 202, 214), (236, 238, 242)],
        "pants": [(30, 32, 40), (46, 49, 60), (66, 70, 84), (96, 100, 116)],
        "hair": [(36, 24, 18), (62, 42, 28), (96, 66, 42)],
        "tie": [(80, 18, 26), (120, 26, 36), (164, 40, 50)],
    },
    "b": {  # camisa celeste, pantalón azul marino, pelo negro, corbata azul
        "shirt": [(112, 140, 180), (156, 184, 218), (204, 222, 242)],
        "pants": [(20, 24, 42), (32, 38, 64), (48, 56, 92), (72, 82, 124)],
        "hair": [(16, 16, 20), (32, 32, 40), (54, 54, 66)],
        "tie": [(22, 30, 70), (36, 50, 110), (58, 78, 150)],
    },
    "c": {  # camisa crema, pantalón gris pardo, pelo rubio, corbata verde
        "shirt": [(168, 156, 116), (212, 202, 158), (242, 236, 206)],
        "pants": [(42, 36, 32), (64, 56, 50), (90, 80, 70), (122, 110, 96)],
        "hair": [(112, 76, 36), (164, 120, 58), (212, 170, 94)],
        "tie": [(24, 56, 40), (38, 88, 62), (60, 124, 88)],
    },
}
# Iguales en todos los looks: zapatos negros y bolso de cuero.
SHOES = [(22, 20, 20), (40, 36, 34), (70, 64, 62), (120, 114, 110)]
BAG = [(46, 28, 20), (72, 46, 30), (102, 68, 44), (138, 96, 62)]
# La parte baja del personaje: el rojo de ahí son zapatos, no bufanda.
FEET_FROM_Y = 38
# Largo de la corbata bajo el nudo, en píxeles.
TIE_LENGTH = 5
# Corte de pelo: se conserva el pelo hasta esta distancia desde la coronilla.
HAIR_KEEP = 11
# Colores originales con los que se rellena lo que tapaban bolso y pelo largo
# (luego se recolorean como el resto).
SKIN_FILL = (193, 106, 125)
SHIRT_FILL = (50, 65, 127)
OUTLINE = (0, 0, 0)
# Media anchura del torso (px) bajo el centro de la cabeza.
TORSO_HALF_WIDTH = 6
# Hebilla de la correa del bolso original.
BAG_BUCKLE = (162, 114, 66)


def classify(rgb, y):
    """Grupo de un color del personaje original, o None si no se toca."""
    r, g, b = (c / 255 for c in rgb)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    hue = h * 360
    if v < 0.05:
        return None  # contorno
    if s < 0.12:
        return "shoes" if y >= FEET_FROM_Y + 3 else "pants"
    if (hue < 15 or hue > 352) and s > 0.6:
        return "shoes" if y >= FEET_FROM_Y else "tie"
    if 205 <= hue <= 240 and s > 0.3:
        return "shirt"
    if 250 <= hue <= 290:
        return "hair"
    if 300 <= hue <= 340 and v < 0.62 and s > 0.4:
        return "bag"
    if rgb == BAG_BUCKLE:
        return "bag"
    return None  # piel, ojos y detalles


def is_skin(rgb):
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    hue = h * 360
    return (hue > 335 or hue < 10) and v > 0.7 and 0.2 < s < 0.6


def tidy(frame):
    """Quita el bolso y corta el pelo largo, rellenando lo que tapaban y
    rehaciendo el contorno negro por donde se borró."""
    pixels = frame.load()
    w, h = frame.size
    opaque = lambda x, y: 0 <= x < w and 0 <= y < h and pixels[x, y][3] > 0
    outline = lambda x, y: opaque(x, y) and pixels[x, y][:3] == OUTLINE

    hair, bag = [], []
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3]:
                group = classify(pixels[x, y][:3], y)
                if group == "hair":
                    hair.append((x, y))
                elif group == "bag":
                    bag.append((x, y))
    if not hair and not bag:
        return
    cut = min(y for _, y in hair) + HAIR_KEEP if hair else h
    hair_set = set(hair)

    # Franja del torso bajo la cabeza: lo que tapaba el bolso dentro de ella
    # es espalda (camisa); lo de fuera sobresalía y se borra.
    center = sum(x for x, _ in hair) / len(hair) if hair else w / 2
    in_torso = lambda x: abs(x - center) <= TORSO_HALF_WIDTH

    # Por fila, dónde hay piel (la cara bajo los mechones).
    def skin_span(y):
        xs = [x for x in range(w) if opaque(x, y) and is_skin(pixels[x, y][:3])]
        return (min(xs), max(xs)) if xs else None
    skin_rows = {y: skin_span(y) for y in range(h)}

    removed = set()
    for x, y in [p for p in hair if p[1] > cut] + bag:
        skin = skin_rows[y]
        if (x, y) in hair_set and skin and skin[0] <= x <= skin[1]:
            pixels[x, y] = (*SKIN_FILL, 255)
        elif in_torso(x):
            pixels[x, y] = (*SHIRT_FILL, 255)
        else:
            pixels[x, y] = (0, 0, 0, 0)
            removed.add((x, y))

    # Contorno suelto que ya no rodea nada: se borra.
    changed = True
    while changed:
        changed = False
        for y in range(h):
            for x in range(w):
                if outline(x, y) and not any(
                        opaque(nx, ny) and not outline(nx, ny)
                        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    pixels[x, y] = (0, 0, 0, 0)
                    removed.add((x, y))
                    changed = True
    # Nuevo contorno donde el borrado dejó el cuerpo al descubierto.
    for x, y in removed:
        if any(opaque(nx, ny) and not outline(nx, ny)
               for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
            pixels[x, y] = (*OUTLINE, 255)


def ramp_color(ramp, value, low, high):
    t = 0.0 if high <= low else (value - low) / (high - low)
    index = min(int(t * len(ramp)), len(ramp) - 1)
    return ramp[max(index, 0)]


def value_bounds(frames):
    """Rango de brillo original de cada grupo en todo el personaje, para que
    un mismo tono se recoloree igual en todos los frames."""
    bounds = {}
    for frame in frames:
        pixels = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                p = pixels[x, y]
                group = classify(p[:3], y) if p[3] else None
                if group:
                    low, high = bounds.get(group, (255, 0))
                    bounds[group] = (min(low, max(p[:3])), max(high, max(p[:3])))
    return bounds


def recolor(frame, look, bounds, front):
    pixels = frame.load()
    groups = {}
    for y in range(frame.height):
        for x in range(frame.width):
            p = pixels[x, y]
            if p[3] == 0:
                continue
            group = classify(p[:3], y)
            if group:
                groups.setdefault(group, []).append((x, y, max(p[:3])))
    ramps = dict(LOOKS[look], shoes=SHOES, bag=BAG)
    for group, points in groups.items():
        low, high = bounds[group]
        for x, y, v in points:
            pixels[x, y] = (*ramp_color(ramps[group], v, low, high), 255)
    if "tie" in groups:
        draw_tie(pixels, groups, ramps, front)


def draw_tie(pixels, groups, ramps, front):
    """La bufanda pasa a ser cuello de camisa. De frente lleva el nudo de la
    corbata al centro y la corbata baja por el pecho sobre la camisa."""
    band = groups["tie"]
    center = round(sum(x for x, _, _ in band) / len(band))
    bottom = max(y for _, y, _ in band)
    collar = ramps["shirt"][-1]
    tie_dark, tie_mid = ramps["tie"][0], ramps["tie"][1]
    for x, y, _ in band:
        knot = front and x in (center - 1, center)
        pixels[x, y] = (*(tie_mid if knot else collar), 255)
    if not front:
        return
    shirt = {(x, y) for x, y, _ in groups.get("shirt", [])}
    for step in range(1, TIE_LENGTH + 1):
        y = bottom + step
        # Punta de 1 px al final; el resto, 2 px con sombra a la izquierda.
        columns = (center,) if step == TIE_LENGTH else (center - 1, center)
        for x in columns:
            if (x, y) in shirt:
                color = tie_dark if x == center - 1 else tie_mid
                pixels[x, y] = (*color, 255)


def find_sheet(src, folder, prefix, direction):
    wanted = f"{prefix}_{direction}.png".lower()
    for path in (src / folder).iterdir():
        if path.name.lower() == wanted:
            return path
    raise FileNotFoundError(src / folder / wanted)


def load_frames(src):
    """Frames del personaje sin bolso ni pelo largo: {animación: [(fila, columna, frame)]}."""
    frames = {}
    for name, (folder, prefix) in ANIMATIONS.items():
        frames[name] = []
        for row, direction in enumerate(DIRECTIONS):
            strip = Image.open(find_sheet(src, folder, prefix, direction)).convert("RGBA")
            for col in range(strip.width // 48):
                frame = strip.crop((col * 48, 0, col * 48 + 48, 64))
                tidy(frame)
                frames[name].append((row, col, frame))
    return frames


def bake(frames, bounds, look):
    out_dir = OUT / look
    out_dir.mkdir(exist_ok=True)
    for name, cells in frames.items():
        sheet = Image.new("RGBA", (8 * 48, len(DIRECTIONS) * 64))
        for row, col, frame in cells:
            frame = frame.copy()
            recolor(frame, look, bounds, row in FRONT_ROWS)
            sheet.paste(frame, (col * 48, row * 64))
        sheet.save(out_dir / f"office_{look}_{name}.png")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[4]
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "estilos" / "1"
    frames = load_frames(src)
    bounds = value_bounds(f for cells in frames.values() for _, _, f in cells)
    for look in LOOKS:
        bake(frames, bounds, look)
        print(f"look {look}: " + ", ".join(f"office_{look}_{n}.png" for n in ANIMATIONS))
