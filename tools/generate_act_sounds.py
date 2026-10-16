"""Generate original Act 1.5 and Act 2 effects with the Python standard library."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "audio"


def write(name, duration, sample):
    rng = random.Random(8051)
    data = bytearray()
    for index in range(round(duration * RATE)):
        time = index / RATE
        value = max(-0.95, min(0.95, sample(time, rng)))
        data.extend(struct.pack("<h", round(value * 32767)))
    with wave.open(str(DEST / f"{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(data)


def pulse(time, period, width):
    return max(0.0, 1.0 - (time % period) / width)


write("balls_wade", 1.1, lambda t, r: r.uniform(-1, 1) * 0.14 *
      (pulse(t, 0.15, 0.08) + pulse(t + 0.07, 0.19, 0.05)))
write("shark_swim", 2.0, lambda t, r: (math.sin(math.tau * (41 + 7 * t) * t) * 0.11
      + r.uniform(-1, 1) * 0.06) * math.sin(math.pi * t / 2.0))
write("shark_bite", 0.8, lambda t, r: (r.uniform(-1, 1) * 0.43
      + math.sin(math.tau * 73 * t) * 0.22) * math.exp(-6 * t))
write("leviathan_rise", 2.0, lambda t, r: (math.sin(math.tau * (24 + 18 * t) * t) * 0.28
      + r.uniform(-1, 1) * 0.10) * math.sin(math.pi * t / 2.0))
write("centipede_legs", 1.3, lambda t, r: r.uniform(-1, 1) * 0.16 *
      (pulse(t, 0.105, 0.024) + pulse(t + 0.05, 0.115, 0.02)))
write("centipede_attack", 1.2, lambda t, r: (r.uniform(-1, 1) * 0.35
      + math.sin(math.tau * (85 - 55 * t) * t) * 0.2) * math.exp(-2.5 * t))
