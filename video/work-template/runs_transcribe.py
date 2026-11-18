"""Nov 8 batch (IMG_4334). Short-form copy of LF01/runs_transcribe.py: split the iPhone voice into voiced runs by energy
(silence >= 0.22 s) and transcribe each run on its own with medium.en, so retakes and false starts
stay separate and word timestamps can't collapse across takes."""
import json, os, sys, wave
if os.path.exists("runs.json"): sys.exit(0)  # a second queued copy of this job does nothing
import numpy as np
from faster_whisper import WhisperModel
HOP = 160  # 10 ms
def load(p):
    w = wave.open(p); return np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
def runs_of(a, on=-36.0, off=-42.0, min_sil=0.22, min_run=0.12):
    fr = a[: len(a) // HOP * HOP].reshape(-1, HOP); db = 20 * np.log10(np.sqrt((fr ** 2).mean(1)) + 1e-9)
    out, start, quiet = [], None, 0
    for i, d in enumerate(db):
        if start is None:
            if d > on: start, quiet = i, 0
        else:
            quiet = quiet + 1 if d < off else 0
            if quiet * HOP / 16000 >= min_sil:
                end = i - quiet + 1
                if (end - start) * HOP / 16000 >= min_run: out.append([start * HOP / 16000, end * HOP / 16000])
                start = None
    if start is not None: out.append([start * HOP / 16000, len(db) * HOP / 16000])
    return out
m = WhisperModel("medium.en", device="cpu", compute_type="int8")
PROMPT = "Dubai, Palm Jumeirah, Canada, Vancouver, vibe coding, vibe coder, CRM, HubSpot, Steam, Telegram, Slack, API, Vercel, CTO, Bank of America, Carl, 226,885, 7,000 pages, 112 dollars, kitchen island."
a = load("voice_16k.wav"); res = []
for s, e in runs_of(a):
    off = max(0, s - 0.15)
    segs, _ = m.transcribe(a[int(off * 16000): int((e + 0.15) * 16000)], language="en", word_timestamps=True,
                           condition_on_previous_text=False, initial_prompt=PROMPT, beam_size=5)
    words = [{"w": w.word.strip(), "s": round(off + w.start, 2), "e": round(off + w.end, 2)} for g in segs for w in g.words]
    res.append({"s": round(s, 2), "e": round(e, 2), "text": " ".join(w["w"] for w in words), "words": words})
json.dump(res, open("runs.json", "w"), indent=0)
for r in res: print(f'{r["s"]:7.2f}-{r["e"]:7.2f}  {r["text"]}')
