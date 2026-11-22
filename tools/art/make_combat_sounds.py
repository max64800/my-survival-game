"""Generates organic medieval combat sounds (no synth tones, no sci-fi).

Replaces the original Kenney "Impact Sounds" hit/parry/swing files, which had
beeps and sci-fi whooshes (owner, Nov 22).  Every sound here is built from
bandpass-filtered noise and fast-decaying inharmonic resonances — real physics,
no pure sine waves sustained long enough to sound electronic.

Needs:  ffmpeg on the PATH, Python + numpy.
Usage:  python tools/art/make_combat_sounds.py
Writes: assets/sfx/hit_0..3.ogg
        assets/sfx/hit_heavy_0..3.ogg
        assets/sfx/parry_0..3.ogg
        assets/sfx/swing_0..3.ogg  (subtle cloth-snap whoosh, quiet)
        assets/sfx/clink_0..3.ogg  (attack-warning metal tap, brief)
        assets/sfx/block_0..3.ogg  (wood-and-leather shield thud)

Sounds:
  hit           Quick leather-and-bone thud (weapon on a skeleton).
  hit_heavy     Deeper thud with more crack (heavy blow or finisher).
  parry         Metal-on-metal klank: fast-decaying inharmonic ring, never beepy.
  swing         Soft cloth-snap air displacement (barely audible; just presence).
"""
import os
import subprocess
import sys

import numpy as np

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
OUT = os.path.join(ROOT, "assets", "sfx")


# ---------------------------------------------------------------- helpers

def lowpass(x, k):
    k = max(1, int(k))
    return np.convolve(x, np.ones(k) / k, mode="same")


def bandpass(x, lo, hi):
    """Very simple bandpass: subtract a wider lowpass from a narrower one."""
    return lowpass(x, max(1, RATE // hi)) - lowpass(x, max(1, RATE // lo))


def fade(x, out_s=0.05):
    n = min(len(x), int(out_s * RATE))
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)
    return x


def adsr(n, a_s=0.003, d_s=0.03, s_lev=0.3, r_s=0.06):
    """Attack / decay / sustain / release envelope."""
    env = np.zeros(n)
    a = int(a_s * RATE)
    d = int(d_s * RATE)
    r = int(r_s * RATE)
    env[:a] = np.linspace(0, 1, max(1, a))
    env[a: a + d] = np.linspace(1, s_lev, max(1, d))
    env[a + d: n - r] = s_lev
    env[n - r:] = np.linspace(s_lev, 0, max(1, r))
    return env


def rasp(x, rng, amount=0.4):
    """Roughens by fast flutter — kills any clean tone."""
    flutter = lowpass(rng.standard_normal(len(x)), 30)
    flutter /= (np.max(np.abs(flutter)) + 1e-9)
    return x * (1 - amount + amount * np.abs(flutter))


# ---------------------------------------------------------------- sounds

def hit(v, rng):
    """Weapon connects: leather-wrapped bone, brief thud + crack."""
    n = int(RATE * 0.075)
    t = np.arange(n) / RATE
    # low thud body (80-350 Hz brown-ish noise)
    noise = rng.standard_normal(n)
    thud = bandpass(noise, 80, 350) * adsr(n, 0.003, 0.025, 0.05, 0.04)
    # mid crack (400-1800 Hz), very brief
    crack = bandpass(rng.standard_normal(n), 400, 1800)
    crack_env = np.exp(-t / 0.012)
    crack *= crack_env * 0.35
    out = rasp(thud * 0.9 + crack, rng, 0.3)
    return fade(out, 0.015)


def hit_heavy(v, rng):
    """Bigger blow: deeper thud, sharper crack, brief bone-crunch texture."""
    n = int(RATE * 0.1)
    t = np.arange(n) / RATE
    # deep body (50-280 Hz)
    noise = rng.standard_normal(n)
    thud = bandpass(noise, 50, 280) * adsr(n, 0.004, 0.035, 0.04, 0.055)
    # sharp crack (600-2500 Hz)
    crack = bandpass(rng.standard_normal(n), 600, 2500)
    crack_env = np.exp(-t / 0.009)
    crack *= crack_env * 0.5
    # crunch texture (2000-5000 Hz), very quiet
    crunch = bandpass(rng.standard_normal(n), 2000, 5000)
    crunch *= np.exp(-t / 0.006) * 0.15
    out = rasp(thud + crack + crunch, rng, 0.3)
    return fade(out, 0.02)


def parry(v, rng):
    """Metal-on-metal block: fast-decaying inharmonic partials — never beepy.

    Real struck-metal sounds have dozens of inharmonic modes (non-integer
    frequency ratios).  Making each mode decay in < 25 ms means none rings
    long enough to sound like a 'beep' — it just clanks.
    """
    n = int(RATE * 0.11)
    t = np.arange(n) / RATE
    # Inharmonic partial set (plate-like, not harmonic series)
    # freqs and decay_ms varied per variant
    base_freqs = [420, 680, 1050, 1580, 2250, 3100, 4200]
    decay_ms   = [22,  16,  13,   10,    8,    6,    5]
    out = np.zeros(n)
    spread = 1.0 + 0.05 * rng.standard_normal()  # slight pitch shift per variant
    for freq, dms in zip(base_freqs, decay_ms):
        f = freq * spread * (1.0 + 0.02 * rng.standard_normal())
        # sine with amplitude-noise modulation (kills "pure beep" quality)
        tone = np.sin(2 * np.pi * f * t)
        noise_mod = 1.0 + 0.25 * lowpass(rng.standard_normal(n), 15)
        env = np.exp(-t / (dms * 0.001))
        out += tone * noise_mod * env * (1.0 / len(base_freqs))
    # Transient click at start (noise burst, 4 ms)
    ck = int(0.004 * RATE)
    click = rng.standard_normal(ck) * np.linspace(1, 0, ck) ** 0.5
    out[:ck] += click * 0.6
    return fade(rasp(out, rng, 0.2), 0.01)


def swing(v, rng):
    """Cloth-snap air displacement: subtle presence, never a sci-fi whoosh."""
    n = int(RATE * 0.09)
    t = np.arange(n) / RATE
    # Air displacement: bandpass noise 300-2500 Hz with quick pass-shape
    noise = rng.standard_normal(n)
    body = bandpass(noise, 300, 2500)
    env = adsr(n, 0.012, 0.02, 0.0, 0.055)
    out = rasp(body * env * 0.6, rng, 0.5)
    return fade(out, 0.015)


# ---------------------------------------------------------------- write

def clink(v, rng):
    """Attack-warning metal tap: very brief inharmonic ring (< 20 ms decay).

    Shorter and lighter than parry — this is the glint warning before a blow,
    not a full block.  Fast-decaying partials prevent any beep quality.
    """
    n = int(RATE * 0.07)
    t = np.arange(n) / RATE
    # Lighter inharmonic set, faster decay than parry
    freqs  = [380, 620,  980, 1550, 2300]
    dec_ms = [14,  10,    8,    6,    4]
    out = np.zeros(n)
    spread = 1.0 + 0.06 * rng.standard_normal()
    for freq, dms in zip(freqs, dec_ms):
        f = freq * spread * (1.0 + 0.03 * rng.standard_normal())
        tone = np.sin(2 * np.pi * f * t)
        noise_mod = 1.0 + 0.3 * lowpass(rng.standard_normal(n), 10)
        env = np.exp(-t / (dms * 0.001))
        out += tone * noise_mod * env * (1.0 / len(freqs))
    # Short transient click
    ck = int(0.003 * RATE)
    click = rng.standard_normal(ck) * np.linspace(1, 0, ck) ** 0.5
    out[:ck] += click * 0.5
    return fade(rasp(out, rng, 0.15), 0.008)


def block(v, rng):
    """Wood-and-leather shield absorbing a blow: dense thud, no ring.

    A plank shield is thick wood wrapped in leather — the dominant sound
    is a compressed thud, not a metallic ring.  Any resonance dies fast
    under the mass of the wood.
    """
    n = int(RATE * 0.09)
    t = np.arange(n) / RATE
    # Main wood thud: mid-low noise burst (120-500 Hz)
    noise = rng.standard_normal(n)
    thud = bandpass(noise, 120, 500) * adsr(n, 0.004, 0.028, 0.08, 0.04)
    # Leather surface snap (500-1800 Hz), very brief
    snap = bandpass(rng.standard_normal(n), 500, 1800)
    snap_env = np.exp(-t / 0.010) * adsr(n, 0.002, 0.01, 0.0, 0.015)
    snap *= snap_env * 0.3
    out = rasp(thud * 0.85 + snap, rng, 0.25)
    return fade(out, 0.015)


SOUNDS = {"hit": hit, "hit_heavy": hit_heavy, "parry": parry, "swing": swing, "clink": clink, "block": block}
VARIANTS = 4


def write(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
    pcm = (x * 32767).astype(np.int16).tobytes()
    path = os.path.join(OUT, name + ".ogg")
    subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-y",
         "-f", "s16le", "-ar", str(RATE), "-ac", "1", "-i", "-",
         "-c:a", "libvorbis", "-q:a", "5", path],
        input=pcm, check=True,
    )


def main():
    import zlib
    for name, make in SOUNDS.items():
        made = [make(v, np.random.default_rng(zlib.crc32(name.encode()) + v))
                for v in range(VARIANTS)]
        for v, x in enumerate(made):
            write("%s_%d" % (name, v), x)
        print("made", name)


if __name__ == "__main__":
    main()
