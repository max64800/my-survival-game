"""Rough-cut a raw talking-head clip: keep the best take of each script line,
tighten pauses, level the audio, export a 1080x1920 MP4.

Usage:
  editor/.venv/bin/python editor/cut.py Raw/IMG_3727.MOV --script video-scripts/001-relaunch.txt
  editor/.venv/bin/python editor/cut.py Raw/IMG_3727.MOV            # no script: heuristic mode

Writes work/<name>/ (words.json, edl.json, cuts.md) and out/<name>_cut.mp4.
To override a decision, edit work/<name>/edl.json and rerun with --from-edl.
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

import numpy as np
from rapidfuzz import fuzz

ROOT = Path(__file__).resolve().parent.parent
PAD_IN, PAD_OUT = 0.05, 0.10   # silence kept before / after the voice: ~0.15 s between lines
TAIL_DB = 8                    # a line's end only extends through sound this much louder than
                               # silence, so breaths after the last word don't count as voice
# iPhone HDR (HLG, BT.2020) -> standard video (BT.709), then a warm natural skin grade
# (Max 2026-11-10: the old red-desaturating grade made him look too pale/white)
GRADE = ("colorspace=all=bt709:iall=bt2020:itrc=bt2020-10:format=yuv420p,"
         "colortemperature=temperature=5200:mix=0.7,eq=contrast=1.08:saturation=1.12:gamma=0.93")
# voice: no noise reduction (the lav is quiet already), less mud, more presence and air
VOICE = ("highpass=f=80,equalizer=f=250:t=o:w=1:g=-3,equalizer=f=3500:t=o:w=1.5:g=3,"
         "highshelf=f=8000:g=3,acompressor=threshold=-20dB:ratio=3:attack=5:release=80,"
         "loudnorm=I=-14:TP=-1:LRA=7")
MAX_GAP = 0.35                 # pauses longer than this inside a take get cut out
MIN_SCORE = 70                 # how closely a take must match its script line (0-100)
QUIET_DB = 22                  # "silence" = this many dB below the loud parts of the voice
FACE_MODEL = ROOT / "video-research" / "models" / "face_yunet.onnx"
# zoom moves, cycled line by line: (zoom at start, zoom at end)
ZOOM_CYCLE = [(1.0, 1.10), (1.18, 1.18), (1.0, 1.0), (1.12, 1.0)]


def norm(t):
    return re.sub(r"[^a-z0-9% ]", "", t.lower().replace("-", " ")).strip()


# ---------- transcription ----------

def load_audio(src):
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(src), "-f", "s16le",
                          "-ac", "1", "-ar", "16000", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(pcm, np.int16).astype(np.float32) / 32768


def transcribe(src, model_size):
    from faster_whisper import WhisperModel
    audio = load_audio(src)
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segs, _ = model.transcribe(audio, word_timestamps=True, language="en",
                               initial_prompt="Um, uh, so. Dubai, Vancouver, realtor.")
    return [{"w": w.word.strip(), "s": round(w.start, 3), "e": round(w.end, 3)}
            for s in segs for w in s.words if w.word.strip()]


# ---------- take selection ----------

def utterances(words, gap=0.6):
    """Group words into runs separated by pauses longer than `gap`."""
    out, cur = [], []
    for i, w in enumerate(words):
        if cur and w["s"] - words[cur[-1]]["e"] > gap:
            out.append(cur); cur = []
        cur.append(i)
    if cur:
        out.append(cur)
    return out


def drop_restarts(words, idx):
    """'the only thing, the only thing that is worse' -> keep from the last restart.
    A restart = the utterance's opening 2-3 words appearing again later in it."""
    toks = [norm(words[i]["w"]) for i in idx]
    for k in (4, 3):   # at least 3 repeated opening words (2 matches normal phrases like "make sure")
        if len(toks) <= k:
            continue
        head = toks[:k]
        last = 0
        # a restart is followed by the rest of the sentence; the same words at the very end
        # ("A king-size ... isn't a king-size") are a callback, not a restart
        for j in range(1, len(toks) - k - 1):
            if toks[j:j + k] == head:
                last = j
        if last:
            return idx[last:]
    return idx


def pick_by_script(words, lines):
    """For each script line, choose the LATEST span of words that matches it well
    (the last take is usually the good one)."""
    toks = [norm(w["w"]) for w in words]
    picks = []
    for line in lines:
        target = norm(line)
        n = len(target.split())
        best, cands = 0, []
        for i in range(len(words)):
            for L in range(max(1, int(n * 0.6)), int(n * 1.5) + 2):
                j = i + L
                if j > len(words):
                    break
                # a take never spans a long silence
                if any(words[k + 1]["s"] - words[k]["e"] > 1.5 for k in range(i, j - 1)):
                    break
                # Whisper sometimes "hears" an earlier sentence again over silence, squeezed
                # into a fraction of a second; real speech needs ~0.15 s per word
                if words[j - 1]["e"] - words[i]["s"] < 0.15 * (j - i):
                    continue
                sc = fuzz.ratio(" ".join(toks[i:j]), target)
                if sc >= MIN_SCORE:
                    cands.append((sc, i, j))
                    best = max(best, sc)
        if not cands:
            picks.append({"line": line, "found": False})
            continue
        good = [c for c in cands if c[0] >= best - 6]
        _, li, lj = max(good, key=lambda c: c[1])          # the latest good take…
        same_take = [c for c in cands if c[1] < lj and c[2] > li]
        sc, i, j = max(same_take, key=lambda c: (c[0], c[2] - c[1]))  # …and its best-matching span
        # tidy: trim a restart inside the chosen span
        idx = drop_restarts(words, list(range(i, j)))
        picks.append({"line": line, "found": True, "score": sc, "idx": idx})
    return picks


def pick_heuristic(words):
    """No script: drop in-utterance restarts, and when two utterances open with the
    same 3 words, keep only the later one."""
    utts = [drop_restarts(words, u) for u in utterances(words)]
    keys = [" ".join(norm(words[i]["w"]) for i in u[:3]) for u in utts]
    picks = []
    for n, u in enumerate(utts):
        if any(fuzz.ratio(keys[n], keys[m]) >= 85 for m in range(n + 1, len(utts))):
            continue
        picks.append({"line": " ".join(words[i]["w"] for i in u), "found": True, "idx": u})
    return picks


# ---------- edit decision list ----------

def voice_envelope(src):
    """Loudness in dB for every 10 ms of the clip, plus the level that counts as silence."""
    a = load_audio(src)
    hop = 160
    frames = a[: len(a) // hop * hop].reshape(-1, hop)
    db = 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-9)
    return db, np.percentile(db, 95) - QUIET_DB


def snap_to_voice(s, e, env, thr, prev_end, next_start, first_end):
    """Whisper's word edges are loose; move them to where the voice really starts/stops.
    Edges only move through continuous voice, and never into a neighbouring (cut) word."""
    fr = lambda t: max(0, min(len(env) - 1, int(round(t * 100))))
    lo, hi = fr(max(s - 0.4, prev_end)), fr(min(e + 0.7, next_start))
    a, b = fr(s), fr(e)
    # Whisper sometimes stretches the first word back over a pause: start after the
    # last silence (>= 0.15 s) inside that first word
    quiet_run, last_gap_end = 0, None
    for f in range(a, fr(first_end)):
        quiet_run = quiet_run + 1 if env[f] <= thr else 0
        if quiet_run >= 15:
            last_gap_end = f + 1
    if last_gap_end is not None:
        a = lo = last_gap_end
    # start: first loud frame at/after Whisper's start, then back up while still loud
    # (hopping over dips up to 60 ms, e.g. the stop inside "Ab-solutely")
    while a < b and env[a] <= thr:
        a += 1
    while True:
        # soft first sounds ("Tw-", "f-", "s-") are quieter than the word itself: allow 15 dB more
        back = [k for k in range(1, 7) if a - k >= lo and env[a - k] > thr - 15]
        if not back:
            break
        a -= max(back)
    # end: last loud frame at/before Whisper's end, then extend while still loud (word tails)
    while b > a and env[b] <= thr:
        b -= 1
    while True:
        fwd = [k for k in range(1, 7) if b + k <= hi and env[b + k] > thr + TAIL_DB]
        if not fwd:
            break
        b += max(fwd)
    return a / 100, (b + 1) / 100


_AUDIO, _MODEL = {}, None


def hear(src, s, e):
    """Re-transcribe a short stretch of the raw clip on its own (no context from earlier lines)."""
    global _MODEL
    from faster_whisper import WhisperModel
    if src not in _AUDIO:
        _AUDIO[src] = load_audio(src)
    if _MODEL is None:
        _MODEL = WhisperModel("small", device="cpu", compute_type="int8")
    clip = _AUDIO[src][int(s * 16000):int(e * 16000)]
    segs, _ = _MODEL.transcribe(clip, language="en", condition_on_previous_text=False)
    return norm(" ".join(x.text for x in segs))


def restart_inside(words, run, env, thr, src=None):
    """Whisper sometimes swallows a false start or a thinking pause into one stretched word.
    If a word in the take is over 1 s long and holds real silence (>= 0.25 s), listen to what
    comes after the silence: if it's the whole line again, everything before was a false start
    (returns (index in run, restart time)); if it's just the rest of the line, it was a pause
    (returns None and the pause is cut out later)."""
    line = " ".join(norm(words[i]["w"]) for i in run)
    for k in reversed(range(len(run) - 1)):
        w = words[run[k]]
        if w["e"] - w["s"] <= 1.0:
            continue
        quiet, last = 0, None
        for f in range(int(w["s"] * 100), min(len(env), int(w["e"] * 100))):
            quiet = quiet + 1 if env[f] <= thr else 0
            if quiet >= 25:
                last = f + 1
        if not last:
            continue
        if src is None:
            return k, last / 100
        after = hear(src, last / 100, words[run[-1]]["e"] + 0.3)
        n = len(after.split())
        if n >= 0.8 * len(line.split()):            # the whole line again -> restart
            return k, last / 100
        prefix = " ".join(line.split()[:n])
        suffix = " ".join(line.split()[-n:]) if n else ""
        if fuzz.ratio(after, prefix) > fuzz.ratio(after, suffix) + 10:
            return k, last / 100                     # starts like the line again -> restart
    return None


def split_on_silence(s, e, env, thr):
    """Cut out silences longer than MAX_GAP inside [s, e], measured on the audio."""
    a, b = int(s * 100), min(len(env), int(e * 100))
    quiet = env[a:b] <= thr
    parts, start, run = [], a, 0
    for f in range(a, b):
        run = run + 1 if quiet[f - a] else 0
        if run == int(MAX_GAP * 100) + 1:
            gap_start = f - run + 1
            if gap_start - start > 10:                      # at least 0.1 s of speech before it
                parts.append((start / 100, gap_start / 100 + PAD_OUT))
            start = None
        if start is None and not quiet[f - a]:
            start = max(a, f - int(PAD_IN * 100))
    if start is not None and b - start > 10:
        parts.append((start / 100, b / 100))
    return parts or [(s, e)]


def build_edl(words, picks, duration, env=None, thr=None, src=None):
    segs = []
    for p in picks:
        if not p.get("found"):
            continue
        idx = p["idx"]
        run = [idx[0]]
        for a, b in zip(idx, idx[1:]):
            if words[b]["s"] - words[a]["e"] > MAX_GAP:
                segs.append(run); run = []
            run.append(b)
        segs.append(run)
    edl = []
    for run in segs:
        s, e = words[run[0]]["s"], words[run[-1]]["e"]
        restart = restart_inside(words, run, env, thr, src) if env is not None else None
        if restart:
            k, s = restart
            run = run[k:]
        if env is not None:
            prev_end = s - 0.2 if restart else (words[run[0] - 1]["e"] if run[0] > 0 else 0.0)
            next_start = words[run[-1] + 1]["s"] if run[-1] + 1 < len(words) else duration
            s, e = snap_to_voice(s, e, env, thr, prev_end, next_start, words[run[0]]["e"])
            s = max(prev_end, s - PAD_IN)
            e = min(next_start, e + PAD_OUT)
        else:
            s, e = s - PAD_IN, e + PAD_OUT
        s, e = max(0.0, s), min(duration, e)
        if env is not None:
            # pauses Whisper hid inside a stretched word: split on the audio itself
            parts = split_on_silence(s, e, env, thr)
            if len(parts) > 1:
                for ps, pe in parts:
                    edl.append({"start": round(ps, 3), "end": round(pe, 3),
                                "text": " ".join(words[i]["w"] for i in run if ps - 0.3 <= words[i]["s"] < pe)})
                continue
        edl.append({"start": round(s, 3), "end": round(e, 3),
                    "text": " ".join(words[i]["w"] for i in run)})
    # merge overlaps, keep script order
    merged = []
    for seg in edl:
        if merged and seg["start"] < merged[-1]["end"] and seg["start"] >= merged[-1]["start"]:
            merged[-1]["end"] = max(merged[-1]["end"], seg["end"])
            merged[-1]["text"] += " " + seg["text"]
        else:
            merged.append(seg)
    if merged and env is not None:
        # the video's last word should land, not get clipped: give it a little extra tail,
        # but never run into the next (unused) take
        last = merged[-1]
        nxt = min((w["s"] for w in words if w["s"] > last["end"]), default=duration)
        last["end"] = round(min(duration, nxt - 0.05, last["end"] + 0.35), 3)
    return merged


# ---------- tone matching: fix lines where the mic got covered ----------

TONE_BANDS = [500, 1000, 2000, 3000, 4000, 6000, 8000, 11000]   # Hz, octave-wide EQ bands
MAX_BOOST = 12                                                    # dB, so noise isn't pumped up
TONE_STRENGTH = 0.85  # share of the tone gap to close (bands overlap, so 100% would overshoot)
HIGH_MAX = 5          # dB cap at 6 kHz and above: that's where hiss lives, and speech needs little there
# on boosted lines only: noise reduction AFTER the EQ (so it removes the hiss the boost lifted),
# then a gentle gate that turns the gaps between words down ~10 dB
DENOISE = "afftdn=nr=10:nf=-40:tn=1"


def band_profile(x, sr=44100):
    """Energy per band in dB, relative to the segment's own overall level."""
    S = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / sr)
    total = S[(f > 100) & (f < 12000)].sum() + 1e-12
    return np.array([10 * np.log10(S[(f > c / 1.41) & (f < c * 1.41)].sum() / total + 1e-12)
                     for c in TONE_BANDS])


def match_tone(src, edl):
    """If the lav gets covered (collar, hand, shirt), a line turns muffled. Compare every
    segment's tone with the clearest segments and EQ the dull ones back towards them."""
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(src), "-f", "s16le",
                          "-ac", "1", "-ar", "44100", "-"], capture_output=True, check=True).stdout
    a = np.frombuffer(pcm, np.int16).astype(np.float32) / 32768
    prof = [band_profile(a[int(s["start"] * 44100):int(s["end"] * 44100)]) for s in edl]
    presence = [p[2:5].mean() for p in prof]                    # 2-4 kHz: where clarity lives
    clear = [p for p, pr in zip(prof, presence) if pr >= np.percentile(presence, 50)]
    ref = np.median(clear, axis=0)
    ref_presence = ref[2:5].mean()
    for seg, p, pr in zip(edl, prof, presence):
        if pr < ref_presence - 4:                               # noticeably duller than the clear lines
            seg["eq"] = [round(float(min(HIGH_MAX if f >= 6000 else MAX_BOOST, max(0.0, g * TONE_STRENGTH))), 1)
                         for f, g in zip(TONE_BANDS, ref - p)]
            # gate threshold just above this line's gaps (a quarter of the way up to speech, in dB),
            # so it quiets the pauses but never soft syllables like the "-thing" in "everything"
            x = a[int(seg["start"] * 44100):int(seg["end"] * 44100)]
            fr = x[: len(x) // 882 * 882].reshape(-1, 882)
            db = 20 * np.log10(np.sqrt((fr ** 2).mean(axis=1)) + 1e-9)
            lo, hi = np.percentile(db, 15), np.percentile(db, 90)
            seg["gate"] = round(float(10 ** ((lo + 0.25 * (hi - lo)) / 20)), 5)
        else:
            seg.pop("eq", None)
            seg.pop("gate", None)
    return edl


def eq_chain(gains, gate=None):
    bands = [f"equalizer=f={f}:t=o:w=1:g={g}" for f, g in zip(TONE_BANDS, gains) if g >= 1]
    if not bands:
        return ""
    # EQ only. Noise reduction and a gate were tried here (for heavily muffled lav takes) but they
    # also ate soft word endings ("and everything" -> "enabled"); badly muffled takes now get a
    # REFILM warning instead, and mild EQ doesn't lift enough hiss to need them.
    return ",".join(bands)


# ---------- motion: face-centred zooms ----------

def face_centre(src, t):
    """Face centre (x, y) in 1080x1920 coordinates at time t, or None."""
    import cv2
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", f"{t:.3f}", "-i", str(src),
                          "-frames:v", "1", "-vf", "scale=540:960", "-f", "rawvideo",
                          "-pix_fmt", "bgr24", "-"], capture_output=True).stdout
    if len(raw) != 540 * 960 * 3:
        return None
    img = np.frombuffer(raw, np.uint8).reshape(960, 540, 3)
    det = cv2.FaceDetectorYN.create(str(FACE_MODEL), "", (540, 960), 0.7)
    _, faces = det.detect(img)
    if faces is None or len(faces) == 0:
        return None
    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])[:4]
    return (x + w / 2) * 2, (y + h / 2) * 2


def add_motion(src, edl):
    """Give every segment a zoom move (cycled) and the face position to centre it on."""
    for n, seg in enumerate(edl):
        seg.setdefault("zoom", list(ZOOM_CYCLE[n % len(ZOOM_CYCLE)]))
        if "face" not in seg:
            d = seg["end"] - seg["start"]
            pts = [p for p in (face_centre(src, seg["start"] + d * f) for f in (0.25, 0.5, 0.75)) if p]
            seg["face"] = ([round(float(np.median([p[0] for p in pts]))), round(float(np.median([p[1] for p in pts])))]
                           if pts else [540, 800])
    return edl


# ---------- render ----------

CARD_W = 380            # picture card width in px (about a third of the frame)
CARD_TOP = 300          # just below the top app bar (Instagram's top 14% is UI)
CARD_MARGIN = 60


def make_card(path):
    """Turn a photo into a small 3:4 card: rounded corners, white border, soft shadow (PNG)."""
    from PIL import Image, ImageDraw, ImageFilter
    out = Path(path).with_suffix(".card.png")
    if out.exists():
        return out
    w, h, border, radius, pad = CARD_W, int(CARD_W * 4 / 3), 8, 28, 24
    img = Image.open(path).convert("RGB")
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    img = img.crop(((img.width - w) // 2, (img.height - h) // 2, (img.width - w) // 2 + w, (img.height - h) // 2 + h))
    W, H = w + 2 * (border + pad), h + 2 * (border + pad)
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([pad + 4, pad + 10, W - pad + 4, H - pad + 10], radius + border, fill=110)
    card.paste((0, 0, 0, 255), (0, 0), shadow.filter(ImageFilter.GaussianBlur(12)))
    frame = Image.new("L", (w + 2 * border, h + 2 * border), 0)
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, w + 2 * border - 1, h + 2 * border - 1], radius + border, fill=255)
    card.paste((255, 255, 255, 255), (pad, pad), frame)
    inner = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inner).rounded_rectangle([0, 0, w - 1, h - 1], radius, fill=255)
    card.paste(img, (pad + border, pad + border), inner)
    card.save(out)
    return out


def broll_filters(seg, n, first_input):
    """Small picture cards on top of the video: [{"file", "from", "to"}] in raw-clip time.
    The card sits in the upper corner away from the face, pops up and fades in/out."""
    inputs, filt, label = [], [], f"v{n}"
    face_x = seg.get("face", [540, 800])[0]
    for k, b in enumerate(seg.get("broll", [])):
        idx = first_input + len(inputs)
        t0, t1 = max(0.0, b["from"] - seg["start"]), min(seg["end"], b["to"]) - seg["start"]
        if t1 - t0 < 0.2:
            continue
        card = make_card(b["file"])
        x = CARD_MARGIN if face_x >= 540 else f"W-w-{CARD_MARGIN}"
        d = t1 - t0
        inputs.append(["-loop", "1", "-framerate", "30", "-t", f"{d:.3f}", "-i", str(card)])
        filt.append(f"[{idx}:v]format=rgba,fade=t=in:st=0:d=0.12:alpha=1,"
                    f"fade=t=out:st={max(0.0, d - 0.1):.3f}:d=0.1:alpha=1,"
                    f"setpts=PTS-STARTPTS+{t0:.3f}/TB[b{n}_{k}]")
        # pop-up: slides up 30 px over the first 0.15 s
        filt.append(f"[{label}][b{n}_{k}]overlay=x={x}:y='{CARD_TOP}+30*max(0,1-(t-{t0:.3f})/0.15)'"
                    f":enable='between(t,{t0:.3f},{t1:.3f})':eof_action=pass[v{n}_{k}]")
        label = f"v{n}_{k}"
    return inputs, filt, label


def render(src, edl, dst):
    parts, labels, extra_inputs = [], [], []
    for n, seg in enumerate(edl):
        z0, z1 = seg.get("zoom", [1.0, 1.0])
        fx, fy = (c * 2 for c in seg.get("face", [540, 800]))   # zoompan runs on a 2x frame
        frames = max(2, round((seg["end"] - seg["start"]) * 30))
        # 2x upscale first so slow zooms don't jitter; face sits at 42% height when zoomed
        motion = (f"{GRADE},scale=2160:3840:force_original_aspect_ratio=increase,crop=2160:3840,"
                  f"zoompan=z='{z0}+({z1}-{z0})*on/{frames - 1}'"
                  f":x='clip({fx}-iw/zoom/2,0,iw-iw/zoom)'"
                  f":y='clip({fy}-ih/zoom*0.42,0,ih-ih/zoom)'"
                  f":d=1:s=1080x1920:fps=30,setsar=1")
        chain = eq_chain(seg["eq"], seg.get("gate")) if seg.get("eq") else ""
        fix = chain + "," if chain else ""
        parts.append(f"[0:v]trim={seg['start']}:{seg['end']},setpts=PTS-STARTPTS,fps=30,{motion}[v{n}];"
                     f"[0:a]atrim={seg['start']}:{seg['end']},asetpts=PTS-STARTPTS,{fix}"
                     f"afade=t=in:d=0.02,afade=t=out:st={max(0, seg['end'] - seg['start'] - 0.03):.3f}:d=0.03[a{n}]")
        b_inputs, b_filt, vlabel = broll_filters(seg, n, 1 + len(extra_inputs))
        extra_inputs += b_inputs
        parts += b_filt
        labels.append(f"[{vlabel}][a{n}]")
    graph = ";".join(parts) + ";" + "".join(labels) + f"concat=n={len(edl)}:v=1:a=1[vout][ac];"
    graph += f"[ac]{VOICE}[aout]"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(src),
                    *[arg for inp in extra_inputs for arg in inp], "-filter_complex", graph,
                    "-map", "[vout]", "-map", "[aout]", "-c:v", "libx264", "-preset", "medium",
                    "-crf", "18", "-pix_fmt", "yuv420p", "-colorspace", "bt709",
                    "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
                    "-c:a", "aac", "-b:a", "192k",
                    "-movflags", "+faststart", str(dst)], check=True)


MUFFLED_REFILM_DB = 8   # a line this much duller than the clear lines can't be rescued well by EQ


def quality_check(src, edl, picks=None):
    """Recording faults that mean "refilm, don't edit": mic dropouts, badly muffled lines,
    and script lines with no usable take. Returns a list of human-readable problems."""
    problems = []
    if picks:
        problems += [f"no usable take for: \"{p['line']}\"" for p in picks if not p.get("found")]
    env, _ = voice_envelope(src)
    for s in edl:
        a, b = int(s["start"] * 100), min(len(env), int(s["end"] * 100))
        zero = env[a:b] < -100                      # digital silence = the wireless mic cut out
        run = longest = 0
        for z in zero:
            run = run + 1 if z else 0
            longest = max(longest, run)
        if longest >= 3:
            problems.append(f"mic dropout ({longest * 10} ms of dead silence) at {s['start']:.1f}s: \"{s['text'][:50]}\"")
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(src), "-f", "s16le",
                          "-ac", "1", "-ar", "44100", "-"], capture_output=True, check=True).stdout
    x = np.frombuffer(pcm, np.int16).astype(np.float32) / 32768
    presence = [band_profile(x[int(s["start"] * 44100):int(s["end"] * 44100)])[2:5].mean() for s in edl]
    clear = np.median([p for p in presence if p >= np.percentile(presence, 50)])
    for s, p in zip(edl, presence):
        if p < clear - MUFFLED_REFILM_DB:
            problems.append(f"muffled audio ({clear - p:.0f} dB duller than your clear lines, mic covered?) "
                            f"at {s['start']:.1f}s: \"{s['text'][:50]}\"")
    return problems


def probe_duration(src):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(src)], capture_output=True, text=True).stdout
    return float(out.strip())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--script", help="text file, one line per spoken sentence")
    ap.add_argument("--model", default="small", help="whisper size: small (fast) or medium (accurate)")
    ap.add_argument("--from-edl", action="store_true", help="render the existing (edited) edl.json")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--no-zoom", action="store_true", help="plain jump cuts, no zoom moves")
    ap.add_argument("--force", action="store_true", help="render even if the quality check says refilm")
    a = ap.parse_args()
    picks = None

    src = Path(a.src).resolve()
    name = src.stem
    work = ROOT / "work" / name
    work.mkdir(parents=True, exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    dst = ROOT / "out" / f"{name}_cut.mp4"

    if a.from_edl:
        edl = json.loads((work / "edl.json").read_text())
    else:
        wpath = work / "words.json"
        if wpath.exists():
            words = json.loads(wpath.read_text())
        else:
            print("transcribing…", flush=True)
            words = transcribe(src, a.model)
            wpath.write_text(json.dumps(words, indent=1))
        if a.script:
            lines = [l.strip() for l in Path(a.script).read_text().splitlines() if l.strip()]
            picks = pick_by_script(words, lines)
        else:
            picks = pick_heuristic(words)
        env, thr = voice_envelope(src)
        edl = build_edl(words, picks, probe_duration(src), env, thr, src)
        if not a.no_zoom:
            print("finding your face for the zooms…", flush=True)
            edl = add_motion(src, edl)
        (work / "edl.json").write_text(json.dumps(edl, indent=1))

        kept = sum(s["end"] - s["start"] for s in edl)
        report = [f"# Cut report: {src.name}", "",
                  f"Raw {probe_duration(src):.1f}s → cut {kept:.1f}s, {len(edl)} segments.", ""]
        if a.script:
            report += ["| Script line | Take used | Match |", "| --- | --- | --- |"]
            for p in picks:
                if p["found"]:
                    t0 = words[p["idx"][0]]["s"]
                    report.append(f"| {p['line']} | at {t0:.1f}s: {' '.join(words[i]['w'] for i in p['idx'])} | {p['score']:.0f} |")
                else:
                    report.append(f"| {p['line']} | **NOT FOUND** | – |")
        report += ["", "## Segments (edit edl.json and rerun with --from-edl to change)", ""]
        report += [f"- {s['start']:.2f}–{s['end']:.2f}s: {s['text']}" for s in edl]
        (work / "cuts.md").write_text("\n".join(report) + "\n")
        print("\n".join(report))

    problems = quality_check(src, edl, picks)
    if problems:
        msg = ["", "⚠️  REFILM RECOMMENDED: recording problems the edit can't fix well:"]
        msg += [f"   - {p}" for p in problems]
        msg += ["   Check the mic (clipped outside the collar, hands below it) and refilm these lines.",
                "   Not rendering. Use --force to render anyway."]
        print("\n".join(msg))
        with open(work / "cuts.md", "a") as f:
            f.write("\n".join(msg) + "\n")
        if not a.force:
            return 1

    if not a.no_render:
        edl = match_tone(src, edl)
        for s in edl:
            if s.get("eq"):
                print(f"  muffled line fixed with EQ {s['eq']}: {s['text'][:50]}")
        (work / "edl.json").write_text(json.dumps(edl, indent=1))
        print("rendering…", flush=True)
        render(src, edl, dst)
        print(f"done: {dst}")


if __name__ == "__main__":
    sys.exit(main())
