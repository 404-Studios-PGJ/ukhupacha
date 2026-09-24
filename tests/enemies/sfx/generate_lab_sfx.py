"""Genera los sonidos del laboratorio de enemigos (sin assets externos).

Uso, desde la raíz del proyecto:
    python3 tests/enemies/sfx/generate_lab_sfx.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).parent


def write(name, samples):
    peak = max(abs(s) for s in samples) or 1
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in samples))


def swing_miss():
    """Whoosh: ruido filtrado cuyo brillo sube y baja, como un arma cortando el aire."""
    rng = random.Random(7)
    dur = 0.22
    out, low, band = [], 0.0, 0.0
    for i in range(int(dur * RATE)):
        t = i / dur / RATE
        cutoff = 300 + 2200 * math.sin(math.pi * t)
        a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
        low += a * (rng.uniform(-1, 1) - low)
        band += 0.35 * (low - band)
        out.append((low - band) * math.sin(math.pi * t) ** 1.5)
    return out


def door():
    """Golpe metálico grave con un breve roce: el mismo al abrir y al cerrar."""
    rng = random.Random(11)
    dur = 0.4
    out, low = [], 0.0
    for i in range(int(dur * RATE)):
        t = i / RATE
        thud = math.exp(-t / 0.08) * (math.sin(2 * math.pi * 85 * t) + 0.4 * math.sin(2 * math.pi * 170 * t))
        clank = math.exp(-t / 0.05) * 0.3 * math.sin(2 * math.pi * 620 * t)
        low += 0.08 * (rng.uniform(-1, 1) - low)
        scrape = 1.5 * low * math.exp(-t / 0.12) * min(t / 0.01, 1)
        out.append(thud + clank + scrape)
    return out


if __name__ == "__main__":
    write("swing_miss", swing_miss())
    write("door", door())
