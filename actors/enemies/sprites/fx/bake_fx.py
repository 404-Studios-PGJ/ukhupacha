"""Extrae y tiñe los sprites de avisos, efectos, proyectiles y HUD de los
enemigos a partir de paquetes CC0, y los deja en esta carpeta.

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sprites/fx/bake_fx.py "<carpeta estilos>"

Fuentes (todas CC0):
- Kenney 1-Bit Pack: https://kenney.nl/assets/1-bit-pack
- Kenney Pixel UI Pack: https://kenney.nl/assets/pixel-ui-pack
- Spark effect (kurohina): https://opengameart.org/content/spark-effect
- Sombra: estilos/1/Shadow.png (paquete del oficinista)
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).parent
TILE = 16
SPARK = 32

# Colores de los avisos (los mismos que usaba el juego).
YELLOW = (255, 210, 63)
RED = (255, 59, 59)
WHITE = (255, 255, 255)
GOLD = (255, 210, 63)
ICE = (200, 230, 255)
ORANGE = (255, 170, 60)
DUST = (170, 170, 180)
BULLET = (255, 240, 200)
ENERGY = (255, 70, 56)
HP_RED = (230, 57, 70)
HP_BACK = (40, 40, 46)

# Tiles del 1-Bit Pack (columna, fila) -> archivo y color.
ONE_BIT = {
    "telegraph_suspicious.png": ((38, 13), YELLOW),   # globo con "?"
    "telegraph_alert.png": ((36, 13), RED),           # globo con "!"
    "telegraph_white.png": ((28, 12), WHITE),         # destello: parry
    "telegraph_red.png": ((35, 21), RED),             # triángulo: esquivar
    "death_dust.png": ((27, 11), DUST),               # nube de polvo
    "bullet.png": ((27, 20), BULLET),                 # anillo pequeño
    "energy_ball.png": ((39, 13), ENERGY),            # círculo
    "aim_dot.png": ((27, 20), RED),                   # punto de la mira
    "marker_corner.png": ((35, 12), RED),             # esquinas de enfoque
    "stun_star.png": ((30, 12), YELLOW),              # destello pequeño
}
# Tiras de chispas (9 frames de 32x32) -> archivo, color y frames usados.
SPARKS = {
    "spark_hit.png": (WHITE, range(9)),
    "spark_critical.png": (GOLD, range(9)),
    "spark_block.png": (ICE, range(9)),
    "spark_slam.png": (RED, range(9)),
    "muzzle_flash.png": (ORANGE, range(3)),
}
# Barra del Pixel UI (fila 27, columnas 6-8: extremo, centro, extremo).
BAR_ROW, BAR_COLUMNS = 27, (6, 7, 8)
UI_STEP = 18  # tiles de 16 px con 2 px de margen


def tint(image, color):
    """Pinta la imagen de un color conservando su brillo y transparencia."""
    image = image.copy()
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a:
                v = max(r, g, b) / 255
                pixels[x, y] = (int(color[0] * v), int(color[1] * v), int(color[2] * v), a)
    return image


def trim(image):
    return image.crop(image.getbbox())


def bake(src):
    one_bit = Image.open(src / "efectos/kenney_1bit/Tilesheet/colored-transparent_packed.png").convert("RGBA")
    for name, ((col, row), color) in ONE_BIT.items():
        tile = one_bit.crop((col * TILE, row * TILE, (col + 1) * TILE, (row + 1) * TILE))
        image = trim(tint(tile, color))
        if name == "marker_corner.png":
            # El tile trae las cuatro esquinas: se usa solo la superior izquierda.
            image = trim(image.crop((0, 0, image.width // 2, image.height // 2)))
        image.save(OUT / name)

    strip = Image.open(src / "efectos/oga_spark_effect/spark_sprite_strip9.png").convert("RGBA")
    for name, (color, frames) in SPARKS.items():
        out = Image.new("RGBA", (SPARK * len(frames), SPARK))
        for i, frame in enumerate(frames):
            out.paste(strip.crop((frame * SPARK, 0, (frame + 1) * SPARK, SPARK)), (i * SPARK, 0))
        tint(out, color).save(OUT / name)

    ui = Image.open(src / "efectos/kenney_pixel_ui/Spritesheet/UIpackSheet_transparent.png").convert("RGBA")
    pieces = [trim(ui.crop((c * UI_STEP, BAR_ROW * UI_STEP, c * UI_STEP + TILE, BAR_ROW * UI_STEP + TILE)))
              for c in BAR_COLUMNS]
    bar = Image.new("RGBA", (sum(p.width for p in pieces), pieces[0].height))
    x = 0
    for piece in pieces:
        bar.paste(piece, (x, 0))
        x += piece.width
    bar = bar.resize((bar.width // 2, bar.height // 2), Image.NEAREST)
    tint(bar, HP_BACK).save(OUT / "hp_bar_back.png")
    tint(bar, HP_RED).save(OUT / "hp_bar_fill.png")

    trim(Image.open(src / "1/Shadow.png").convert("RGBA")).save(OUT / "shadow.png")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[4]
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "estilos"
    bake(src)
    print(", ".join(sorted(p.name for p in OUT.glob("*.png"))))
