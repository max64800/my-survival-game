"""Synthesise the editor's sound-effects kit (whoosh, swish, pop, impact, tick, type, ding, riser).

Everything is generated from noise and sine waves, so the sounds are ours and need no licence.
Usage: python editor/sfx.py <out_dir>
"""
import sys
import wave
from pathlib import Path

import numpy as np

SR = 48000
rng = np.random.default_rng(7)


def env(n, attack, release_shape=3.0):
    t = np.linspace(0, 1, n)
    a = max(1, int(n * attack))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a) ** 2
    e[a:] = (1 - np.linspace(0, 1, n - a)) ** release_shape
    return e


def sweep_noise(dur, f0, f1, q=2.0):
    """Noise through a resonant band-pass whose centre glides f0 -> f1 (the 'air' in a whoosh)."""
    n = int(SR * dur)
    x = rng.standard_normal(n)
    fc = np.geomspace(f0, f1, n)
    y = np.zeros(n)
    s1 = s2 = 0.0
    for i in range(n):  # state-variable filter
        f = 2 * np.sin(np.pi * fc[i] / SR)
        hp = x[i] - s1 / q - s2
        s1 += f * hp
        s2 += f * s1
        y[i] = s1
    return y / (np.abs(y).max() + 1e-9)


def tone(dur, f0, f1=None, kind="sin"):
    n = int(SR * dur)
    f = np.geomspace(f0, f1 or f0, n)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)


def whoosh():
    d = 0.55
    y = sweep_noise(d, 300, 3500, q=1.6) * env(int(SR * d), 0.55, 2.2)
    return y * 0.9


def swish():
    d = 0.28
    return sweep_noise(d, 1800, 6000, q=1.2) * env(int(SR * d), 0.35, 2.5) * 0.6


def pop():
    d = 0.12
    y = tone(d, 900, 240) * env(int(SR * d), 0.04, 4)
    click = rng.standard_normal(int(SR * d)) * env(int(SR * d), 0.0, 40) * 0.3
    return (y + click) * 0.8


def impact():
    d = 0.9
    n = int(SR * d)
    boom = tone(d, 95, 38) * env(n, 0.01, 5)
    thud = sweep_noise(d, 900, 120, q=0.9) * env(n, 0.0, 14) * 0.7
    return np.tanh((boom + thud) * 1.6) * 0.9


def tick():
    d = 0.035
    return tone(d, 2400) * env(int(SR * d), 0.0, 8) * 0.5


def type_key():
    d = 0.045
    n = int(SR * d)
    return (rng.standard_normal(n) * env(n, 0.0, 20) * 0.35 + tone(d, 1600) * env(n, 0.0, 30) * 0.2)


def ding():
    d = 0.9
    n = int(SR * d)
    return (tone(d, 1318.5) * 0.5 + tone(d, 1975.5) * 0.25) * env(n, 0.005, 3) * 0.6


def riser():
    d = 1.2
    n = int(SR * d)
    y = sweep_noise(d, 200, 5000, q=2.5) * np.linspace(0, 1, n) ** 2
    y[-int(SR * 0.04):] *= np.linspace(1, 0, int(SR * 0.04))
    return y * 0.7


# ---------- extended kit (2026-10-12, Max: "all the sound effects were pretty much the same") ----------
# More roles + pitch variants so every video and every event type can sound different. All synthesised: no licences.
def _n(d): return int(SR * d)


def click():            # crisp UI tap
    d = 0.05; n = _n(d)
    return (tone(d, 3200, 1800) * env(n, 0.0, 25) * 0.5 + rng.standard_normal(n) * env(n, 0.0, 60) * 0.25)


def glitch():           # digital stutter: bursts of square-ish buzz
    d = 0.32; n = _n(d); y = np.zeros(n)
    for k in range(6):
        a = int(rng.uniform(0, n - _n(0.04))); m = _n(rng.uniform(0.012, 0.035))
        f = rng.choice([180, 420, 900, 1500])
        seg = np.sign(np.sin(2 * np.pi * f * np.arange(m) / SR)) * 0.4 + rng.standard_normal(m) * 0.2
        y[a:a + m] += seg
    return np.tanh(y * 1.5) * env(n, 0.0, 1.2) * 0.6


def page_flip():        # paper flick: bright noise sweep with a soft slap
    d = 0.3; n = _n(d)
    y = sweep_noise(d, 5000, 1500, q=0.8) * env(n, 0.15, 3)
    slap = rng.standard_normal(n) * env(n, 0.0, 30) * 0.4
    slap = np.roll(slap, _n(0.17))
    return (y * 0.6 + slap) * 0.7


def shine():            # sparkle: quick rising glints
    d = 0.6; n = _n(d); y = np.zeros(n)
    for k, f in enumerate([2637, 3136, 3951, 4699]):
        a = _n(0.06 * k); m = n - a
        y[a:] += tone(m / SR, f) * env(m, 0.002, 6) * (0.35 - 0.05 * k)
    return y * 0.6


def low_hit():          # sub boom for the 2-3 biggest reveals only
    d = 1.4; n = _n(d)
    return np.tanh(tone(d, 62, 32) * env(n, 0.005, 3.2) * 2.2) * 0.85


def metal_riser():      # metallic, inharmonic rise
    d = 1.3; n = _n(d); y = np.zeros(n)
    for ratio in [1.0, 2.76, 5.4, 8.93]:
        y += tone(d, 180 * ratio, 900 * ratio) * (0.3 / ratio ** 0.5)
    y *= np.linspace(0, 1, n) ** 2.2
    y[-_n(0.03):] *= np.linspace(1, 0, _n(0.03))
    return y * 0.7


def count_roll():       # odometer / counter rolling: fast ticks that slow down
    d = 1.0; n = _n(d); y = np.zeros(n); t = 0.0; gap = 0.028
    while t < d - 0.03:
        a = _n(t); m = _n(0.02)
        y[a:a + m] += tone(0.02, 2900 - t * 900) * env(m, 0.0, 10) * 0.4
        t += gap; gap *= 1.07
    return y * 0.7


def shutter():          # camera shutter: two clicks
    d = 0.18; n = _n(d); y = np.zeros(n)
    for a in [0, _n(0.07)]:
        m = _n(0.03); y[a:a + m] += rng.standard_normal(m) * env(m, 0.0, 15) * 0.5 + tone(0.03, 1200) * env(m, 0.0, 20) * 0.3
    return y * 0.8


def bubble():           # liquid blob / goo merge
    d = 0.22; n = _n(d)
    return tone(d, 300, 1100) * env(n, 0.02, 3.5) * 0.6


def drop():             # water droplet
    d = 0.3; n = _n(d)
    return (tone(d, 1400, 520) * env(n, 0.0, 6) * 0.5 + tone(d, 2600, 2200) * env(n, 0.0, 14) * 0.15)


def stamp():            # rubber stamp / slam on paper
    d = 0.5; n = _n(d)
    thud = tone(d, 140, 60) * env(n, 0.0, 9)
    paper = sweep_noise(d, 3000, 800, q=0.7) * env(n, 0.0, 18) * 0.5
    return np.tanh((thud + paper) * 1.8) * 0.8


def coin():             # coin clink (money, ROI)
    d = 0.7; n = _n(d)
    y = sum(tone(d, f) * a for f, a in [(2093, 0.4), (3322, 0.25), (5040, 0.15)])
    return y * env(n, 0.0, 5) * 0.6


def notif():            # two-tone notification (original intervals)
    d = 0.5; n = _n(d); h = _n(0.11)
    y = np.zeros(n)
    y[:h] += tone(0.11, 1046.5) * env(h, 0.01, 2) * 0.45
    y[h:] += tone((n - h) / SR, 1568) * env(n - h, 0.01, 4) * 0.45
    return y


def keys():             # burst of keyboard typing
    d = 0.5; n = _n(d); y = np.zeros(n); t = 0.0
    while t < d - 0.05:
        a = _n(t); m = _n(0.035)
        y[a:a + m] += rng.standard_normal(m) * env(m, 0.0, 22) * rng.uniform(0.2, 0.4) + tone(0.035, rng.uniform(1300, 1900)) * env(m, 0.0, 30) * 0.15
        t += rng.uniform(0.045, 0.09)
    return y * 0.8


def crumple():          # paper crumple / unfold
    d = 0.6; n = _n(d); y = np.zeros(n)
    for k in range(40):
        a = int(rng.uniform(0, n - _n(0.02))); m = _n(rng.uniform(0.004, 0.015))
        y[a:a + m] += rng.standard_normal(m) * rng.uniform(0.2, 0.6)
    return sweep_noise(d, 3000, 3000, q=0.5) * 0.08 + y * env(n, 0.1, 1.5) * 0.6


def zip_():             # quick zip / slide
    d = 0.22; n = _n(d)
    return sweep_noise(d, 800, 7000, q=3) * env(n, 0.1, 2) * 0.55


def chime():            # soft success chime, rising
    d = 1.0; n = _n(d); y = np.zeros(n)
    for k, f in enumerate([784, 988, 1175]):
        a = _n(0.08 * k); m = n - a
        y[a:] += tone(m / SR, f) * env(m, 0.005, 3.5) * 0.3
    return y * 0.7


def thock():            # soft wooden thock (calm UI)
    d = 0.14; n = _n(d)
    return (tone(d, 520, 380) * env(n, 0.0, 9) * 0.6 + rng.standard_normal(n) * env(n, 0.0, 50) * 0.15)


def pitched(fn, ratio):
    """resample a sound so variants of the same role don't sound identical"""
    y = fn(); idx = np.arange(0, len(y), ratio)
    return np.interp(idx, np.arange(len(y)), y)


def save(path, y):
    y = np.clip(y, -1, 1)
    pcm = (y * 32767 * 0.9).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "editor/motion/public/sfx")
    out.mkdir(parents=True, exist_ok=True)
    kit = [("whoosh", whoosh), ("swish", swish), ("pop", pop), ("impact", impact),
           ("tick", tick), ("type", type_key), ("ding", ding), ("riser", riser),
           ("click", click), ("glitch", glitch), ("page_flip", page_flip), ("shine", shine), ("low_hit", low_hit),
           ("metal_riser", metal_riser), ("count_roll", count_roll), ("shutter", shutter), ("bubble", bubble),
           ("drop", drop), ("stamp", stamp), ("coin", coin), ("notif", notif), ("keys", keys), ("crumple", crumple),
           ("zip", zip_), ("chime", chime), ("thock", thock),
           # pitch variants of the most-used roles (_b lower/longer, _c higher/shorter)
           ("whoosh_b", lambda: pitched(whoosh, 0.8)), ("whoosh_c", lambda: pitched(whoosh, 1.25)),
           ("swish_b", lambda: pitched(swish, 0.8)), ("swish_c", lambda: pitched(swish, 1.3)),
           ("pop_b", lambda: pitched(pop, 0.75)), ("pop_c", lambda: pitched(pop, 1.35)),
           ("impact_b", lambda: pitched(impact, 0.85)), ("ding_b", lambda: pitched(ding, 0.84)),
           ("tick_b", lambda: pitched(tick, 0.7))]
    for name, fn in kit:
        save(out / f"{name}.wav", fn())
        print("wrote", out / f"{name}.wav")
