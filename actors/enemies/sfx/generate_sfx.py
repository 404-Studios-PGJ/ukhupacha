"""Genera los sonidos de aviso de los enemigos (sin assets externos).

Uso, desde la raíz del proyecto:
    python3 actors/enemies/sfx/generate_sfx.py
"""
import math
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


if __name__ == "__main__":
    write("telegraph_white", tone(0.35, white))
    write("telegraph_red", tone(0.42, red))
    write("alert", tone(0.16, alert))
    write("suspicious", tone(0.2, suspicious))
