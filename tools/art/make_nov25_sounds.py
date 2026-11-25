"""Four sounds from the owner's Nov 25 play notes, from REAL recordings only (owner's sound rule), all CC0 from
Freesound (links and authors in CREDITS.md), cut and layered by us:

  hit_blunt    F854 "the mace makes a sword sound": a mace landing. A wooden weapon knock (541990) for the blow,
               a body hit (276600) for the thump and a short bone crunch (192146) underneath. No blade swish.
  bat_death    F881: a cave bat's last squeak (bats squeaking in a real cave, 404152) that drops in pitch as it
               fades, then a soft wing flop (our bat_flap) as it drops.
  snail_death  F881: a Rock Snail's shell cracking (egg shell crunch 272224, slowed = a bigger, harder shell) with a
               bone crunch (192146) and a wet slump (our snail_spit, slowed and dulled).
  refill       F883 "refilling the lantern sounds like a gulp of water": a real oil lantern's lid opening (516740),
               a short pour of oil (699231) and the lid clicking shut (516740). Replaces refill_0/1.

Usage:  python tools/art/make_nov25_sounds.py <folder with the Freesound files, named <id>.mp3>
        (get each from https://freesound.org/s/<id>/ : 541990 276600 192146 404152 272224 516740 699231)
Writes: assets/sfx/hit_blunt_0..2, bat_death_0..1, snail_death_0..1, refill_0..1 (.ogg)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_creature_sounds import RATE, load, ours, speed, trim, mix, lowpass, fade, write  # noqa: E402

SRC = ""


def fs(sound_id, start=0.0, end=None):
    """A piece of a Freesound recording (seconds)."""
    x = load(os.path.join(SRC, "%s.mp3" % sound_id))
    return x[int(start * RATE): int(end * RATE) if end else None]


def fade_in(x, s=0.01):
    n = min(len(x), int(s * RATE))
    x = x.copy()
    x[:n] *= np.linspace(0, 1, n)
    return x


def glide(x, f0, f1):
    """Play it like a tape that slows down as it goes (the pitch slides from f0 to f1 times normal)."""
    rate = np.linspace(f0, f1, len(x))
    pos = np.cumsum(rate)
    pos = pos[pos < len(x) - 1]
    return np.interp(pos, np.arange(len(x)), x)


def norm(x):
    return x / (np.max(np.abs(x)) + 1e-9)


def hit_blunt(v):
    knock = norm(trim(fs(541990, 0.1, 0.6)))
    knock = lowpass(speed(knock, [0.8, 0.72, 0.88][v]), 3)        # lower: a heavy head, not a stick
    body = norm(trim(fs(276600, 0.15, 0.6)))
    body = speed(body, [0.9, 0.8, 1.0][v])
    crunch = norm(trim(fs(192146, 0.05, 0.55)))
    crunch = lowpass(speed(crunch, [1.1, 0.95, 1.2][v]), 4)[: int(0.25 * RATE)]
    return fade(mix((knock, 0.0, 0.9), (body, 0.0, 0.8), (crunch, 0.015, 0.35)), 0.12)


def bat_death(v):
    squeak = norm(fs(404152, *[(67.95, 68.55), (62.5, 63.1)][v]))
    squeak = fade(fade_in(glide(squeak, 1.05, 0.55), 0.01), 0.15)  # the squeal sinks as it dies away
    flop = lowpass(speed(norm(trim(ours("bat_flap_%d" % v))), 0.6), 5)
    return mix((squeak, 0.0, 1.0), (flop, len(squeak) / RATE - 0.1, 0.45))


def snail_death(v):
    shell = norm(trim(fs(272224, 0.08, 1.15)))
    shell = fade(speed(shell, [0.62, 0.55][v]), 0.2)
    crunch = lowpass(speed(norm(trim(fs(192146, 0.05, 0.55))), [0.7, 0.62][v]), 5)
    slump = lowpass(speed(norm(trim(ours("snail_spit_%d" % v))), 0.55), 9)
    return fade(mix((shell, 0.0, 0.9), (crunch, 0.02, 0.55), (slump, 0.35, 0.5)), 0.2)


def refill(v):
    lid_open = fade(fade_in(norm(fs(516740, 4.2, 4.6))), 0.08)
    pour = norm(fs(699231, *[(26.6, 27.7), (27.8, 28.9)][v]))
    pour = fade(fade_in(pour, 0.12), 0.25)
    lid_shut = fade(fade_in(norm(fs(516740, *[(20.1, 20.45), (15.22, 15.55)][v]))), 0.08)
    return mix((lid_open, 0.0, 0.8), (pour, 0.3, 0.55), (lid_shut, 0.3 + len(pour) / RATE + 0.05, 0.85))


SOUNDS = {"hit_blunt": (hit_blunt, 3), "bat_death": (bat_death, 2), "snail_death": (snail_death, 2), "refill": (refill, 2)}


def main():
    global SRC
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    SRC = sys.argv[1]
    for name, (make, n) in SOUNDS.items():
        for v in range(n):
            x = make(v)
            write("%s_%d" % (name, v), x)
            print("%s_%d  %.2f s" % (name, v, len(x) / RATE))


if __name__ == "__main__":
    main()
