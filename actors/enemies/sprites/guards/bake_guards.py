"""Combina las capas de Mana Seed (cuerpo, ropa, cabeza, arma, escudo) en
hojas listas para Godot, una carpeta por guardia.

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sprites/guards/bake_guards.py "<carpeta de Mana Seed>"

Carpeta por defecto: "estilos/extras" en la raíz (Mana Seed renombrado).
Asset: Mana Seed Character Base (demo gratuita), de Seliel the Shaper
(https://seliel-the-shaper.itch.io/character-base), uso comercial y no comercial.

Cada página es de 512x512 con frames de 64x64 (8x8). Filas 0-3 y 4-7:
abajo, arriba, derecha, izquierda.
"""
import math
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
PAGES = ("p1", "pONE1", "pONE2", "pONE3")
FRAME = 64

# Qué lleva cada guardia: (código, variante de paleta).
GUARDS = {
    # Enemigo medio: guardias de seguridad con uniforme negro (ropa forestal
    # recoloreada con franja amarilla reflectante) y la cabeza rapada.
    # "weapon" da la posición de la mano y la dirección en cada frame;
    # "custom_weapon" dibuja otra arma en su lugar.
    "shield": {  # antidisturbios: tonfa y escudo
        "skin": "03",
        "outfit": ("fstr", "01"),
        "uniform": True,
        "head": None,
        "weapon": ("mc01", "03"),
        "custom_weapon": "tonfa",
        "shield": ("sh01", "03"),
    },
    "pistol": {  # con pistola: dispara de lejos y da culatazos de cerca
        "skin": "07",
        "outfit": ("fstr", "01"),
        "uniform": True,
        "head": None,
        "weapon": ("sw01", "01"),
        "custom_weapon": "pistol",
        "shield": None,
        # El disparo usa la estocada: sus líneas de velocidad van en rojo.
        "red_thrust": True,
    },
}

# Uniforme de seguridad: colores de la ropa forestal v01 -> negro.
UNIFORM = {
    (91, 24, 57): (22, 22, 26),     # mangas
    (141, 34, 70): (38, 38, 44),
    (190, 86, 103): (62, 62, 70),
    (113, 101, 88): (30, 30, 34),   # chaleco (y botas)
    (166, 152, 120): (50, 50, 56),
    (199, 196, 162): (78, 78, 86),
    (30, 43, 65): (20, 20, 24),     # pantalón
    (60, 85, 117): (44, 44, 52),
}
VEST_COLORS = {(113, 101, 88), (166, 152, 120), (199, 196, 162)}
# Franja reflectante: filas bajo el borde superior del chaleco.
STRIPE = {3: (240, 200, 48), 4: (186, 146, 30)}
# Las botas usan los colores del chaleco: se excluyen las últimas filas.
BOOT_ROWS = 6
# Armas de estilos/armas/Police officer/Weapons.png, reducidas a la escala
# de Mana Seed y con su misma paleta.
WEAPON_COLORS = {
    "K": (0, 0, 0),        # contorno
    "B": (39, 39, 39),     # cuerpo
    "H": (62, 62, 62),     # brillo
    "M": (209, 209, 209),  # marcas de la tonfa
}
# Pistola apuntando a la derecha; "g" es la empuñadura (donde va la mano).
PISTOL = (
    "KKKKKKKKK.",
    "KHHHHHHHHK",
    "KBBBBBBBBK",
    ".KBgKKKKK.",
    ".KBBK.....",
    ".KBBK.....",
    "..KK......",
)
TONFA_LENGTH = (10, 16)  # se adapta al largo del arma original
TONFA_HANDLE_AT = 4      # distancia de la mano al mango lateral

# Por dirección (fila % 4): arma y escudo delante (True) o detrás del cuerpo.
# Mirando a la derecha el brazo de la espada queda hacia la cámara; a la
# izquierda, el del escudo. Mirando arriba, el cuerpo tapa lo que sostiene.
IN_FRONT = {
    0: {"weapon": True, "shield": True},    # abajo
    1: {"weapon": False, "shield": False},  # arriba
    2: {"weapon": True, "shield": False},   # derecha
    3: {"weapon": False, "shield": True},   # izquierda
}

# Estela del tajo (color único dentro de la capa del arma) y su versión roja,
# para que un ataque rojo no muestre una estela blanca (blanco = parry).
TRAIL_COLOR = (244, 249, 248, 255)
RED_TRAIL_COLOR = (255, 64, 56, 255)
# Estocada en la página pONE3: columnas 0-3 de la mitad inferior.
RED_THRUST_BOX = (0, 4 * FRAME, 4 * FRAME, 8 * FRAME)


# Al desenvainar (pONE1) la estela sobra: se confundiría con un ataque blanco.
NO_TRAIL = (0, 0, 0, 0)


def tint_trail(image, box, color):
    region = image.crop(box)
    pixels = region.load()
    for y in range(region.height):
        for x in range(region.width):
            if pixels[x, y] == TRAIL_COLOR:
                pixels[x, y] = color
    image.paste(region, box[:2])


def uniform(outfit):
    """Recolorea la ropa a negro y pinta la franja amarilla en el chaleco, a la
    altura del pecho, frame por frame."""
    pixels = outfit.load()
    for top in range(0, outfit.height, FRAME):
        for left in range(0, outfit.width, FRAME):
            cells = [(x, y) for y in range(top, top + FRAME) for x in range(left, left + FRAME)
                     if pixels[x, y][3]]
            if not cells:
                continue
            feet = max(y for _, y in cells)
            vest = [(x, y) for x, y in cells
                    if pixels[x, y][:3] in VEST_COLORS and y < feet - BOOT_ROWS]
            vest_top = min(y for _, y in vest) if vest else None
            for x, y in cells:
                rgb = pixels[x, y][:3]
                stripe = STRIPE.get(y - vest_top) if vest_top is not None else None
                if stripe and (x, y) in vest:
                    pixels[x, y] = (*stripe, 255)
                elif rgb in UNIFORM:
                    pixels[x, y] = (*UNIFORM[rgb], 255)


def weapon_axis(pixels, left, top):
    """Mano y dirección del arma original dentro de un frame: eje principal
    de sus píxeles (sin la estela); la mano es el extremo más cercano al
    centro del frame, donde está el cuerpo."""
    points = [(x, y) for y in range(top, top + FRAME) for x in range(left, left + FRAME)
              if pixels[x, y][3] and pixels[x, y] != TRAIL_COLOR]
    if len(points) < 3:
        return None
    mx = sum(x for x, _ in points) / len(points)
    my = sum(y for _, y in points) / len(points)
    sxx = sum((x - mx) ** 2 for x, _ in points)
    syy = sum((y - my) ** 2 for _, y in points)
    sxy = sum((x - mx) * (y - my) for x, y in points)
    angle = 0.5 * math.atan2(2 * sxy, sxx - syy)
    ux, uy = math.cos(angle), math.sin(angle)
    proj = [(x - mx) * ux + (y - my) * uy for x, y in points]
    ends = [(mx + ux * min(proj), my + uy * min(proj)), (mx + ux * max(proj), my + uy * max(proj))]
    center = (left + FRAME / 2, top + FRAME / 2 + 6)
    ends.sort(key=lambda e: math.dist(e, center))
    hand, tip = ends
    length = math.dist(hand, tip)
    if length < 1:
        return None
    return hand, ((tip[0] - hand[0]) / length, (tip[1] - hand[1]) / length), length


def draw_tonfa(pixels, hand, direction, length):
    length = max(TONFA_LENGTH[0], min(TONFA_LENGTH[1], length))
    dx, dy = direction
    side = (-dy, dx) if dy <= 0 else (dy, -dx)  # el mango cuelga hacia abajo
    # El brillo solo en horizontal o vertical: en diagonal se escalona.
    straight = min(abs(dx), abs(dy)) < 0.35
    drawn = {}
    steps = int(length * 2)
    for i in range(steps + 1):
        d = i / 2
        x, y = round(hand[0] + dx * d), round(hand[1] + dy * d)
        drawn[(x, y)] = "M" if 2 <= d <= 3 else "B"
        if straight:
            hx, hy = round(x - side[0]), round(y - side[1])
            drawn.setdefault((hx, hy), "H")
    for k in range(1, 4):  # mango lateral
        x = round(hand[0] + dx * TONFA_HANDLE_AT + side[0] * k)
        y = round(hand[1] + dy * TONFA_HANDLE_AT + side[1] * k)
        drawn[(x, y)] = "B"
    paint_with_outline(pixels, drawn)


def draw_pistol(pixels, hand, direction):
    angle = math.degrees(math.atan2(direction[1], direction[0]))
    snapped = round(angle / 45) * 45
    rows = PISTOL[::-1] if abs(snapped) > 90 else PISTOL  # no queda al revés
    grip = next((x, y) for y, row in enumerate(rows) for x, c in enumerate(row) if c == "g")
    cos_a, sin_a = math.cos(math.radians(snapped)), math.sin(math.radians(snapped))
    drawn = {}
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c == ".":
                continue
            vx, vy = x - grip[0], y - grip[1]
            rx = round(hand[0] + vx * cos_a - vy * sin_a)
            ry = round(hand[1] + vx * sin_a + vy * cos_a)
            drawn[(rx, ry)] = "B" if c == "g" else c
    paint_with_outline(pixels, drawn)


def paint_with_outline(pixels, drawn):
    """Pinta el arma y le pone contorno negro donde no lo trae."""
    for (x, y), c in drawn.items():
        pixels[x, y] = (*WEAPON_COLORS[c], 255)
    for (x, y), c in drawn.items():
        if c == "K":
            continue
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in drawn and pixels[nx, ny][3] == 0:
                pixels[nx, ny] = (*WEAPON_COLORS["K"], 255)


def replace_weapon(weapon, kind):
    """Cambia el arma de Mana Seed por la tonfa o la pistola en cada frame,
    conservando la estela de los tajos."""
    source = weapon.copy()
    src = source.load()
    pixels = weapon.load()
    for y in range(weapon.height):
        for x in range(weapon.width):
            if pixels[x, y] != TRAIL_COLOR:
                pixels[x, y] = (0, 0, 0, 0)
    for top in range(0, weapon.height, FRAME):
        for left in range(0, weapon.width, FRAME):
            axis = weapon_axis(src, left, top)
            if axis is None:
                continue
            hand, direction, length = axis
            if kind == "tonfa":
                draw_tonfa(pixels, hand, direction, length)
            else:
                draw_pistol(pixels, hand, direction)


def layer(src, page, name, code=None, variant=None):
    folder = src / f"char_a_{page}"
    if name == "0bas":
        path = folder / f"char_a_{page}_0bas_humn_v{variant}.png"
    else:
        path = folder / name / f"char_a_{page}_{name}_{code}_v{variant}.png"
    return Image.open(path).convert("RGBA")


def bake(src, guard):
    out_dir = OUT / guard
    out_dir.mkdir(exist_ok=True)
    look = GUARDS[guard]
    for page in PAGES:
        body = layer(src, page, "0bas", variant=look["skin"])
        outfit = layer(src, page, "1out", *look["outfit"])
        if look.get("uniform"):
            uniform(outfit)
        body.alpha_composite(outfit)
        if look["head"]:
            body.alpha_composite(layer(src, page, *look["head"]))
        tools = {}
        # La página 1 (caminar sin combate) no lleva armas: van envainadas.
        if page != "p1":
            tools["weapon"] = layer(src, page, "6tla", *look["weapon"])
            if look.get("custom_weapon"):
                replace_weapon(tools["weapon"], look["custom_weapon"])
            if page == "pONE1":
                tint_trail(tools["weapon"], (0, 0, *tools["weapon"].size), NO_TRAIL)
            if page == "pONE3" and look.get("red_thrust"):
                tint_trail(tools["weapon"], RED_THRUST_BOX, RED_TRAIL_COLOR)
            if look["shield"]:
                tools["shield"] = layer(src, page, "7tlb", *look["shield"])

        sheet = Image.new("RGBA", body.size)
        for row in range(body.height // FRAME):
            box = (0, row * FRAME, body.width, (row + 1) * FRAME)
            order = IN_FRONT[row % 4]
            strip = Image.new("RGBA", (body.width, FRAME))
            for name in ("shield", "weapon"):
                if name in tools and not order[name]:
                    strip.alpha_composite(tools[name].crop(box))
            strip.alpha_composite(body.crop(box))
            for name in ("shield", "weapon"):
                if name in tools and order[name]:
                    strip.alpha_composite(tools[name].crop(box))
            sheet.paste(strip, (0, row * FRAME))
        sheet.save(out_dir / f"{guard}_{page}.png")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[4]
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "estilos" / "extras"
    for name in GUARDS:
        bake(src, name)
        print(f"{name}: {', '.join(f'{name}_{p}.png' for p in PAGES)}")
