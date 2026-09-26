"""Genera los sonidos de aviso e impacto de los enemigos (sin assets externos).

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sfx/generate_sfx.py
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


def env(t, attack, decay):
    return min(t / attack, 1.0) * math.exp(-t / decay)


def tone(dur, fn):
    return [fn(i / RATE) for i in range(int(dur * RATE))]


def white(t):
    """ "Tin" metálico agudo: oportunidad de parry."""
    return env(t, 0.003, 0.09) * (
        math.sin(2 * math.pi * 1760 * t)
        + 0.5 * math.sin(2 * math.pi * 2640 * t)
        + 0.25 * math.sin(2 * math.pi * 3960 * t))


def red(t):
    """Dos golpes graves con zumbido: hay que esquivar."""
    s = 0.0
    for start in (0.0, 0.16):
        u = t - start
        if u >= 0:
            f = 140 - 40 * min(u / 0.12, 1)
            s += env(u, 0.004, 0.07) * (
                math.sin(2 * math.pi * f * u)
                + 0.3 * math.copysign(1, math.sin(2 * math.pi * f * 2 * u)))
    return s


def alert(t):
    """ "!": pitido ascendente corto."""
    return env(t, 0.004, 0.06) * math.sin(2 * math.pi * (700 * t + 1600 * t * t))


def suspicious(t):
    """ "?": pitido suave que sube y baja."""
    return env(t, 0.01, 0.08) * math.sin(2 * math.pi * (520 * t + 300 * t * t - 600 * t * t * t))


def enemy_swing_miss():
    """Whoosh grave: el arma del enemigo corta el aire."""
    rng = random.Random(3)
    dur = 0.3
    out, low, band = [], 0.0, 0.0
    for i in range(int(dur * RATE)):
        t = i / dur / RATE
        cutoff = 150 + 1100 * math.sin(math.pi * t)
        a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
        low += a * (rng.uniform(-1, 1) - low)
        band += 0.25 * (low - band)
        out.append((low - band) * math.sin(math.pi * t) ** 1.5)
    return out


def enemy_hit(t):
    """Golpe seco: el ataque del enemigo conecta."""
    rng = random.Random(int(t * RATE))
    thud = math.exp(-t / 0.05) * math.sin(2 * math.pi * (110 - 60 * min(t / 0.08, 1)) * t)
    crunch = math.exp(-t / 0.015) * rng.uniform(-1, 1) * 0.6
    return thud + crunch


def enemy_clank(t):
    """Choque metálico: bloqueo o parry del Player."""
    rng = random.Random(int(t * RATE) + 99)
    ring = sum(a * math.exp(-t / d) * math.sin(2 * math.pi * f * t)
               for f, a, d in ((920, 1.0, 0.12), (1480, 0.6, 0.08), (2630, 0.35, 0.05)))
    click = math.exp(-t / 0.004) * rng.uniform(-1, 1)
    return ring + click


def enemy_gunshot(t):
    """Disparo: chasquido de ruido brillante con un golpe grave debajo."""
    rng = random.Random(int(t * RATE) + 7)
    crack = math.exp(-t / 0.025) * rng.uniform(-1, 1)
    boom = math.exp(-t / 0.08) * math.sin(2 * math.pi * (95 - 50 * min(t / 0.15, 1)) * t)
    return crack + 0.9 * boom


def enemy_slam(t):
    """Aterrizaje del salto: golpe muy grave con retumbe de escombros."""
    rng = random.Random(int(t * RATE) + 21)
    boom = math.exp(-t / 0.18) * math.sin(2 * math.pi * (70 - 35 * min(t / 0.3, 1)) * t)
    rumble = math.exp(-t / 0.12) * rng.uniform(-1, 1) * 0.5
    return boom + rumble


if __name__ == "__main__":
    write("telegraph_white", tone(0.35, white))
    write("telegraph_red", tone(0.42, red))
    write("alert", tone(0.16, alert))
    write("suspicious", tone(0.2, suspicious))
    write("enemy_swing_miss", enemy_swing_miss())
    write("enemy_hit", tone(0.22, enemy_hit))
    write("enemy_clank", tone(0.3, enemy_clank))
    write("enemy_gunshot", tone(0.3, enemy_gunshot))
    write("enemy_slam", tone(0.6, enemy_slam))
