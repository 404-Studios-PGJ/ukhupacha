#!/usr/bin/env python3
"""Original procedural UKHUPACHA placeholders; stdlib only, deterministic PCM.

Run: python3 audio/generate_placeholders.py
Verify reproducibility without writes: python3 audio/generate_placeholders.py --check
No recordings, samples, cultural melodies or third-party source audio.
Licensing/release decision: TODO_LICENSE (project owners).
"""

import argparse
import io
import math
from pathlib import Path
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
MUSIC = {
    "ambience_a": (110.0, 165.0, 220.0),
    "ambience_b": (73.5, 110.0, 147.0),
    "ambience_c": (55.0, 82.5, 137.5),
    "combat": (98.0, 147.0, 196.0),
}
SFX = {
    "menu": (0.10, 720.0, 880.0),
    "door": (0.55, 90.0, 45.0),
    "pickup": (0.32, 440.0, 880.0),
    "alarm": (0.65, 660.0, 440.0),
    "hit": (0.16, 140.0, 45.0),
    "parry": (0.30, 1600.0, 800.0),
    "rift": (0.90, 110.0, 660.0),
}


def encode(samples):
    out = io.BytesIO()
    with wave.open(out, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", round(max(-0.9, min(0.9, s)) * 32767)) for s in samples))
    return out.getvalue()


def ambience(name, frequencies):
    duration = 4.0
    values = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        edge = min(1.0, t / 0.025, (duration - t) / 0.025)
        pad = sum(math.sin(math.tau * f * t) for f in frequencies) / len(frequencies)
        pulse = 0.72 + 0.28 * math.sin(math.tau * (2.0 if name == "combat" else 0.25) * t)
        values.append(0.28 * edge * pad * pulse)
    return encode(values)


def effect(name, specification):
    duration, first, last = specification
    rng = random.Random("UKHUPACHA/v1/" + name)
    values = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        u = t / duration
        phase = math.tau * (first * t + (last - first) * t * t / (2 * duration))
        envelope = min(1.0, t / 0.008) * (1.0 - u) ** 2
        noise = rng.uniform(-1.0, 1.0) * (0.35 if name in ("door", "hit", "rift") else 0.03)
        tone = 0.65 * math.sin(phase) + 0.12 * math.sin(phase * 2)
        values.append(0.45 * envelope * (tone + noise))
    return encode(values)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = {ROOT / "music" / (name + ".wav"): ambience(name, frequencies) for name, frequencies in MUSIC.items()}
    files.update({ROOT / "sfx" / (name + ".wav"): effect(name, spec) for name, spec in SFX.items()})
    failed = []
    for path, data in files.items():
        if args.check:
            if not path.exists() or path.read_bytes() != data:
                failed.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    if failed:
        raise SystemExit("Mismatch: " + ", ".join(failed))
    print(f"{'Verified' if args.check else 'Generated'} {len(files)} original mono PCM16 WAVs at {RATE} Hz.")


if __name__ == "__main__":
    main()
