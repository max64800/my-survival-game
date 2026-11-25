"""Each creature's own last sound (owner, Nov 25: "fix the enemy dying, it doesn't match anyone": beetles, spiders,
the skeleton miners and the ghosts all died with the one dull body-thump, F881 only gave bats and snails their own).

Real recordings only (owner's sound rule), all already in the game (CC0, see CREDITS.md), reshaped with the same
helpers as make_creature_sounds.py:
  beetle_death  the shell cracking, a long hiss running out, the heavy body settling
  spider_death  a short sharp hiss, a little crunch, legs curling up (quick ticks)
  bones_death   a skeleton falling into a heap: woody bone clacks tumbling, then the skull's knock
  ghost_death   the mist blowing apart: a slow low breath sinking away under a cloth whump, no thump at all

Usage:  python tools/art/make_death_sounds.py
Writes: assets/sfx/{beetle,spider,bones,ghost}_death_0..1.ogg
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_creature_sounds import RATE, ours, speed, trim, mix, lowpass, fade, rasp, write  # noqa: E402


def sink(x, top=1.0, bottom=0.6):
    """Slide the pitch down over the sound (it runs out of breath)."""
    rate = np.linspace(top, bottom, len(x))
    pos = np.cumsum(rate)
    pos = pos[pos < len(x) - 1]
    return np.interp(pos, np.arange(len(x)), x)


def beetle_death(v, rng):
    crack = fade(speed(trim(ours("shell_clank_%d" % v)), 0.7), 0.1)
    crunch = lowpass(speed(trim(ours("dig_break_0")), [0.8, 0.7][v]), 4)
    hiss = trim(ours("beetle_hiss_0"))
    hiss = sink(speed(hiss, 0.85), 1.0, 0.55) * np.linspace(1.0, 0.0, len(sink(speed(hiss, 0.85), 1.0, 0.55))) ** 1.2
    settle = fade(lowpass(speed(trim(ours("hit_heavy_%d" % v)), 0.6), 20), 0.15)
    return fade(mix((crack, 0.0, 0.8), (crunch, 0.02, 0.5), (hiss, 0.08, 0.6), (settle, 0.45, 0.6)), 0.2)


def spider_death(v, rng):
    hiss = trim(ours("beetle_hiss_0"))
    hiss = speed(hiss, [1.45, 1.6][v])[: int(0.35 * RATE)]
    hiss = sink(hiss, 1.0, 0.7)
    hiss = hiss * np.linspace(1.0, 0.0, len(hiss)) ** 1.5
    crunch = fade(speed(trim(ours("dig_break_0")), 1.5), 0.05)
    tick = fade(speed(trim(ours("build_wood_0")), 2.2)[: int(0.06 * RATE)], 0.02)
    parts = [(hiss, 0.0, 0.8), (crunch, 0.03, 0.45)]
    t = 0.22
    for i in range(4):  # legs curling in, quicker and softer
        parts.append((tick, t, 0.35 * (0.8 ** i)))
        t += 0.07 - 0.01 * i + float(rng.uniform(0, 0.015))
    return fade(mix(*parts), 0.1)


def bones_death(v, rng):
    clack = trim(ours("build_wood_0"))
    parts = []
    t = 0.0
    for i in range(9):  # bones tumbling into a heap, the gaps closing up, each a little different
        bit = speed(clack, float(rng.uniform(1.5, 2.3)))[: int(0.09 * RATE)]
        parts.append((fade(bit, 0.03), t, 0.75 * (0.88 ** i) * float(rng.uniform(0.7, 1.0))))
        t += float(rng.uniform(0.05, 0.11)) * (1.0 - 0.05 * i)
    skull = fade(speed(trim(ours("chop_%d" % v)), 1.25), 0.08)
    parts.append((skull, t + 0.06, 0.6))
    rattle = fade(speed(trim(ours("clink_%d" % (v + 1))), 0.8), 0.1)  # (its iron gear landing last)
    parts.append((lowpass(rattle, 6), t + 0.12, 0.25))
    return fade(mix(*parts), 0.15)


def ghost_death(v, rng):
    breath = trim(ours("beetle_hiss_0"))
    breath = lowpass(speed(breath, 0.45 + 0.05 * v), 22)
    breath = rasp(breath, rng, 0.35)
    breath = sink(breath, 1.0, 0.65)[: int(1.5 * RATE)]
    breath = breath * np.linspace(1.0, 0.0, len(breath)) ** 1.3
    moan = lowpass(sink(speed(trim(ours("beetle_rumble_%d" % v)), 0.55), 1.0, 0.7), 30)[: int(1.6 * RATE)]
    moan = moan * np.linspace(0.6, 0.0, len(moan)) ** 1.5
    cloth = lowpass(speed(trim(ours("bat_flap_%d" % (v + 1))), 0.5), 6)
    return fade(mix((cloth, 0.0, 0.7), (breath, 0.04, 0.8), (moan, 0.1, 0.5)), 0.35)


SOUNDS = {"beetle_death": beetle_death, "spider_death": spider_death, "bones_death": bones_death,
          "ghost_death": ghost_death}


def main():
    rng = np.random.default_rng(902)
    for name, make in SOUNDS.items():
        for v in range(2):
            x = make(v, rng)
            write("%s_%d" % (name, v), x)
            print("%s_%d  %.2f s" % (name, v, len(x) / RATE))


if __name__ == "__main__":
    main()
