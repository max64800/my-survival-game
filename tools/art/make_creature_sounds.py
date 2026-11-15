"""Makes the creature sounds, and swaps out the menu-ish sounds, using REAL recordings only.

Owner (Nov 14, 2026): "make sure the sounds are not futuristic... they do not match medieval."
So nothing here is a pure computer tone (those sound like lasers and menu beeps). Every sound starts
from a real recording of leather, cloth, wood, stone or metal (Kenney's CC0 packs), then gets
pitched, sped up, layered and given rough noise, like a foley artist in a film studio.

Needs:  ffmpeg on the PATH, and Kenney's "RPG Audio" pack (CC0), unzipped:
        https://opengameart.org/content/50-rpg-sound-effects  (or kenney.nl/assets/rpg-audio)
Usage:  python tools/art/make_creature_sounds.py <folder with the RPG pack .ogg files>
Writes: assets/sfx/<name>_<0..3>.ogg

  Creature sounds:
    bat_screech   a creaking door, sped way up, gets a raspy squeal (no clean pitch)
    bat_flap      cloth snapped fast = a leathery wing beat
    snail_slam    a heavy hit, pitched down, with a wet leathery flop
    shell_clunk   a wooden door thud, pitched down = the shell knocking shut
    shell_clank   "pickaxe bounces off hard rock" (our clink), lower = hitting the hidden shell
    beetle_hiss   rough breathy hiss with little clicking mandibles (noise only)
    beetle_rumble rough rumble with fast scraping feet (footsteps sped up)
  Replaced because they sounded like computer menus:
    open / close  the bag: cloth and leather rustles (was a rising "whoosh" sweep)
    pickup        a pouch rustle (was a synthesizer pluck)
    refill        the lantern: a metal latch (was a pure beep)
    death         a monster falls: a heavy thud and flop (was a pure electronic tone)
"""
import os
import subprocess
import sys
import zlib

import numpy as np

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
OUT = os.path.join(ROOT, "assets", "sfx")
PACK = ""


def load(path):
    """Any sound file -> mono float array (via ffmpeg)."""
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-ac", "1", "-ar", str(RATE),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.int16).astype(float) / 32768.0


def rpg(name):
    return load(os.path.join(PACK, name + ".ogg"))


def ours(name):
    return load(os.path.join(OUT, name + ".ogg"))


def speed(x, factor):
    """Play faster (higher and shorter) or slower (lower and longer), like a tape."""
    n = max(2, int(len(x) / factor))
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


def trim(x, quiet=0.02):
    idx = np.where(np.abs(x) > quiet * np.max(np.abs(x)))[0]
    return x[idx[0]: idx[-1] + 1] if idx.size else x


def mix(*parts):
    """Layer sounds: (sound, start_seconds, volume) ..."""
    end = max(int(s * RATE) + len(x) for x, s, _ in parts)
    out = np.zeros(end)
    for x, s, v in parts:
        i = int(s * RATE)
        out[i:i + len(x)] += x * v
    return out


def lowpass(x, k):
    k = max(1, int(k))
    return np.convolve(x, np.ones(k) / k, mode="same")


def fade(x, out_s=0.05):
    n = min(len(x), int(out_s * RATE))
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)
    return x


def rasp(x, rng, amount=0.5):
    """Roughens a sound: fast uneven flutter, like air through a throat (kills any clean tone)."""
    flutter = lowpass(rng.standard_normal(len(x)), 40)
    flutter = flutter / (np.max(np.abs(flutter)) + 1e-9)
    return x * (1 - amount + amount * np.abs(flutter))


# ---------------------------------------------------------------- creature sounds

def bat_screech(v, rng):
    creak = trim(rpg(["creak1", "creak2", "creak3", "creak2"][v]))
    squeal = speed(creak, rng.uniform(1.7, 2.0))[: int(0.4 * RATE)]
    squeal = rasp(squeal / (np.max(np.abs(squeal)) + 1e-9), rng, 0.35)
    breath = (rng.standard_normal(len(squeal)) - lowpass(rng.standard_normal(len(squeal)), 6)) * 0.03
    return fade(mix((squeal, 0, 1.0), (breath * np.abs(squeal) ** 0.5, 0, 1.0)), 0.08)


def bat_flap(v, rng):
    src = trim(rpg(["cloth1", "cloth2", "cloth3", "cloth4"][v]))
    snap = speed(src, rng.uniform(1.3, 1.6))[: int(0.22 * RATE)]
    return fade(lowpass(snap, 3), 0.06)


def snail_slam(v, rng):
    hit = speed(trim(ours("hit_heavy_%d" % v)), rng.uniform(0.65, 0.75))
    flop = speed(trim(rpg("dropLeather")), rng.uniform(0.7, 0.85))
    return fade(mix((hit, 0, 1.0), (flop, 0.02, 0.7)), 0.12)


def shell_clunk(v, rng):
    door = trim(rpg(["doorClose_1", "doorClose_2", "doorClose_3", "doorClose_4"][v]))
    return fade(speed(door, rng.uniform(0.7, 0.8))[: int(0.5 * RATE)], 0.1)


def shell_clank(v, rng):
    clink = speed(trim(ours("clink_%d" % v)), rng.uniform(0.72, 0.82))
    thud = speed(trim(ours("hit_%d" % v)), 0.85)
    return fade(mix((clink, 0, 0.8), (thud, 0, 0.8)), 0.1)


def beetle_hiss(v, rng):
    n = int(RATE * rng.uniform(0.45, 0.6))
    hiss = rng.standard_normal(n) - lowpass(rng.standard_normal(n), 10)
    hiss = rasp(lowpass(hiss, 2), rng, 0.6)
    shape = np.minimum(np.linspace(0, 6, n), 1) * np.linspace(1, 0, n) ** 1.5
    clicks = np.zeros(n)
    for c in np.arange(0.02, n / RATE - 0.02, 1.0 / rng.uniform(22, 30)):  # mandibles: noise ticks
        i = int(c * RATE)
        k = min(n - i, 90)
        clicks[i:i + k] += rng.standard_normal(k) * np.exp(-np.arange(k) / 12.0)
    return hiss * shape * 0.5 + clicks * 0.6


def beetle_rumble(v, rng):
    n = int(RATE * 1.1)
    brown = np.cumsum(rng.standard_normal(n))
    brown -= lowpass(brown, 300)
    brown /= np.max(np.abs(brown)) + 1e-9
    rise = np.linspace(0.25, 1.0, n) ** 1.5
    parts = [(brown * rise, 0, 0.9)]
    t, i = 0.0, 0
    while t < 1.0:  # six feet scraping, faster and faster
        step = speed(trim(rpg("footstep%02d" % ((i + v) % 10))), rng.uniform(0.8, 1.0))
        parts.append((step, t, 0.35 + 0.5 * t))
        t += 0.11 - 0.05 * t
        i += 1
    return fade(mix(*parts)[:n], 0.15)


# ---------------------------------------------------------------- medieval replacements

def open_(v, rng):
    return trim(rpg(["cloth1", "cloth2", "handleSmallLeather", "beltHandle1"][v]))


def close(v, rng):
    return trim(rpg(["clothBelt", "clothBelt2", "handleSmallLeather2", "beltHandle2"][v]))


def pickup(v, rng):
    src = trim(rpg(["cloth3", "cloth4", "handleSmallLeather", "handleSmallLeather2"][v]))
    return fade(speed(src, 1.15)[: int(0.3 * RATE)], 0.06)


def refill(v, rng):
    src = trim(rpg(["metalLatch", "metalClick", "metalLatch", "metalClick"][v]))
    return speed(src, [1.0, 1.0, 0.9, 0.9][v])


def death(v, rng):
    thud = speed(trim(ours("hit_heavy_%d" % v)), 0.8)
    flop = trim(rpg("dropLeather"))
    return fade(mix((thud, 0, 1.0), (flop, 0.08, 0.8)), 0.15)


SOUNDS = {
    "bat_screech": bat_screech, "bat_flap": bat_flap, "snail_slam": snail_slam,
    "shell_clunk": shell_clunk, "shell_clank": shell_clank, "beetle_hiss": beetle_hiss,
    "beetle_rumble": beetle_rumble,
    "open": open_, "close": close, "pickup": pickup, "refill": refill, "death": death,
}
VARIANTS = 4  # = Sfx.MAX_VARIANTS, so every old variant gets replaced


def write(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
    pcm = (x * 32767).astype(np.int16).tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", str(RATE), "-ac", "1",
                    "-i", "-", "-c:a", "libvorbis", "-q:a", "5", path], input=pcm, check=True)


def main():
    global PACK
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    PACK = sys.argv[1]
    for name, make in SOUNDS.items():
        made = [make(v, np.random.default_rng(zlib.crc32(name.encode()) + v)) for v in range(VARIANTS)]
        for v, x in enumerate(made):
            write("%s_%d" % (name, v), x)
        print("made", name)


if __name__ == "__main__":
    main()
