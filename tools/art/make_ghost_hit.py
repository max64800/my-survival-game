"""The sound of a weapon hitting a ghost (owner, Nov 25, F874: "it sounds like a bell, or a spear").

A ghost is mist on old bones, not metal: so no ring at all. Real recordings only (owner's sound rule), all of them
already in the game (CC0, see CREDITS.md): a cloth snap slowed down (the weapon tearing through its misty robe),
a body-fall thump made dull and low (the blow landing in something soft), and a breathy rush fading after it
(the mist blowing apart). Same helpers as make_creature_sounds.py.

Usage:  python tools/art/make_ghost_hit.py
Writes: assets/sfx/ghost_hit_0..2.ogg
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_creature_sounds import RATE, ours, speed, trim, mix, lowpass, fade, rasp, write  # noqa: E402


def ghost_hit(v, rng):
    cloth = trim(ours("bat_flap_%d" % (v % 4)))
    cloth = lowpass(speed(cloth, 0.55 + 0.08 * v), 6)          # a slow heavy cloth whump, no crack
    thump = trim(ours("hit_heavy_%d" % (v % 3)))
    thump = fade(lowpass(speed(thump, 0.7), 28), 0.12)        # dull and low: no ring left in it
    breath = trim(ours("beetle_hiss_0"))
    breath = lowpass(speed(breath, 0.6), 18)[: int(0.5 * RATE)]
    breath = rasp(breath, rng, 0.4) * np.linspace(1.0, 0.0, len(breath)) ** 1.5
    return fade(mix((cloth, 0.0, 0.9), (thump, 0.01, 0.55), (breath, 0.05, 0.35)), 0.15)


def main():
    rng = np.random.default_rng(874)
    for v in range(3):
        write("ghost_hit_%d" % v, ghost_hit(v, rng))
        print("ghost_hit_%d" % v)


if __name__ == "__main__":
    main()
