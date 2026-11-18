"""039 cut (copy of 033 recut_v2.py) (cut-timing-hard-rules, Max's v1 notes 2026-11-01): every boundary from the AUDIO.
- start of each line: wav2vec first-word start (align.json), moved earlier while the voice is still above threshold
  (never clip an onset), then LEAD s of air;
- end of each line: from the wav2vec last-word end, walk forward through the decaying voice until it stays below
  threshold, then TAIL s (never ends on a timestamp alone);
- inside a line: any silence > 0.2 s is cut out, keeping 0.06 s on each side.
v1 -> v2 changes: "Absolute disaster" now keeps his whole sentence (it runs into "because" with no gap, so any earlier
end clips "disaster"); "eventually" gets its full tail. Writes edl.json (cut.py format) + the as-filmed script."""
import json, wave
import numpy as np

LEAD, TAIL, KEEP, MAX_IN = 0.02, 0.09, 0.06, 0.20
w = wave.open("voice_16k.wav")
a = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
HOP = 160                                                   # 10 ms
fr = a[: len(a) // HOP * HOP].reshape(-1, HOP)
DB = 20 * np.log10(np.sqrt((fr ** 2).mean(1)) + 1e-9)
db = lambda t: DB[int(round(t * 100))]
# high band (> 4 kHz) per 10 ms: final "s"/"ts"/"t" are quiet in RMS but loud up here, so line ends follow this too
_S = np.abs(np.fft.rfft(fr * np.hanning(HOP), axis=1)) ** 2
HF = 10 * np.log10(_S[:, np.fft.rfftfreq(HOP, 1 / 16000) > 4000].sum(1) + 1e-12)
hf = lambda t: HF[int(round(t * 100))]
AL = json.load(open("align.json"))

# (align.json line index, text as said, raw end override from whisper/energy for words beyond the align window)
LINES = [
    (0, "Here's my most expensive mistake as a CTO."),
    (1, "Our hosting bill should be anywhere from 20 to 30 bucks."),
    (2, "And this month, it was"),
    (3, "$112."),
    (4, "I'm a vibe coder so I have absolutely no idea what I'm doing."),
    (5, "First, I pushed way too many updates and way too many new features in a single month."),
    (6, "Then I had a bot check all 7,000 of our pages in our website every single hour to see if Google found them."),
    (7, "That is 160,000 checks every single day."),
    (8, "So before you launch anything, just make sure there is a budget alert system."),
    (9, "Cheap lesson, but it could have been so much worse."),
]
LAST_WORD_END, NEXT_SPEECH, ONSET_MIN = {}, {}, {}
END_MAX = {2: 60.12}   # "it was..." trails off into breath: voice is below -40 dB from 60.07, so stop there (else a 0.3 s gap before $112)

def thr_for(s, e):
    seg = DB[int(s * 100): int(e * 100)]
    floor, peak = np.percentile(seg, 10), np.percentile(seg, 90)
    return max(floor + 6, peak - 30)

edl, report = [], []
for li, text in LINES:
    ws = AL[li]["words"]
    s_w, e_w = ws[0][1], LAST_WORD_END.get(li, ws[-1][2])
    thr = thr_for(s_w - 0.5, e_w + 0.5)
    on = s_w
    while db(on - 0.01) > thr and on > s_w - 0.12 and on > ONSET_MIN.get(li, 0): on -= 0.01   # onset: back up while voiced (max 0.12 s)
    off = e_w
    limit = NEXT_SPEECH.get(li, e_w + 0.6)
    quiet = 0
    t = e_w
    hthr = np.percentile(HF[int((e_w + 0.3) * 100): int((e_w + 1.0) * 100)], 30) + 10   # hiss floor after the line + 10 dB
    loud_end = e_w
    while t < limit:                                                      # end: 5 quiet frames in a row (loudness AND hiss band)
        if db(t) >= thr: loud_end = t
        quiet = quiet + 1 if db(t) < thr and hf(t) < hthr else 0
        if quiet >= 5 or t - loud_end > 0.15: break                       # a final "s" lasts <= 0.15 s; longer hiss = breath
        t += 0.01
    off = t - 0.04
    # split on silences > MAX_IN inside [on, off]
    voiced = [db(x) >= thr for x in np.arange(on, off, 0.01)]
    pieces, start, run = [], on, 0
    for k, v in enumerate(voiced):
        x = on + k * 0.01
        if not v: run += 1
        else:
            if run * 0.01 > MAX_IN:
                gap_s = x - run * 0.01
                pieces.append((start, gap_s + KEEP)); start = x - KEEP
            run = 0
    pieces.append((start, off))
    for k, (ps, pe) in enumerate(pieces):
        seg_s = round(ps - (LEAD if k == 0 else 0), 3)
        seg_e = round(pe + (TAIL if k == len(pieces) - 1 else 0), 3)
        if k == len(pieces) - 1 and li in END_MAX: seg_e = min(seg_e, END_MAX[li])
        edl.append({"start": seg_s, "end": seg_e, "text": text if k == 0 else "", "line": li, "zoom": [1.0, 1.0], "face": [540, 800]})
    report.append(f"{li:2d} on {on:7.2f} off {off:7.2f} pieces {len(pieces)} thr {thr:5.1f}  {text[:50]}")
print("\n".join(report))
for i in range(len(edl) - 1):     # no overlap with the next segment of the same take
    if edl[i + 1]["start"] < edl[i]["end"]: edl[i]["end"] = edl[i + 1]["start"]
json.dump(edl, open("edl.json", "w"), indent=1)
txt = [t for _, t in LINES]; txt[2:4] = [txt[2] + " " + txt[3]]
open("../../video-scripts/039-cto-vercel-mistake-as-filmed.txt", "w").write("\n".join(txt) + "\n")
print(f"{len(edl)} segments, {sum(x['end'] - x['start'] for x in edl):.2f} s")
