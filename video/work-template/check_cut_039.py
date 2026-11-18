"""039 (copy of 033 check_cut_v2.py) post-cut check (cut-timing-hard-rules): on out/IMG_4334_cut.mp4
1. wav2vec literal read + forced alignment against the as-filmed script; prints each line's last word with its confidence,
   and every word under 0.35 confidence (a clipped ending shows up as a low score or a missing letter in the literal read);
2. silence scan: any stretch > 0.2 s that is quiet in loudness AND in the > 4 kHz band (so a final "s" isn't counted);
3. lead-in at frame 0.
Run: <torch-python> -I check_cut_v2.py"""
import re, subprocess
import numpy as np, torch, torchaudio
import torchaudio.functional as F

pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", "../../out/IMG_4334_cut.mp4", "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                     capture_output=True, check=True).stdout
a = np.frombuffer(pcm, np.int16).astype(np.float32) / 32768
lines = [l.strip() for l in open("../../video-scripts/039-cto-vercel-mistake-as-filmed.txt") if l.strip()]
SAY = [("$112", "a hundred and twelve dollars"), ("160,000", "a hundred and sixty thousand"), ("7,000", "seven thousand"),
       ("20", "twenty"), ("30", "thirty"), ("CTO", "c t o")]
def spoken(s):
    for a, b in SAY: s = s.replace(a, b)
    return re.sub(r"[^a-z' ]", "", s.lower()).split()

B = torchaudio.pipelines.WAV2VEC2_ASR_LARGE_LV60K_960H
m = B.get_model().eval(); LAB = B.get_labels(); IDX = {c: i for i, c in enumerate(LAB)}
with torch.inference_mode(): em, _ = m(torch.from_numpy(a)[None])
em = torch.log_softmax(em, -1); fr = len(a) / 16000 / em.shape[1]
ids = em[0].argmax(-1).tolist(); lit, prev = [], None
for k in ids:
    if k != prev and LAB[k] != "-": lit.append(LAB[k])
    prev = k
print("LITERAL:", "".join(lit).replace("|", " ").lower())
words = [w for l in lines for w in spoken(l)]
chars = "|".join(words).upper()
ali, sc = F.forced_align(em, torch.tensor([[IDX[c] for c in chars]], dtype=torch.int32), blank=0)
spans = F.merge_tokens(ali[0], sc[0].exp())
per, cur = [], []
for sp, ch in zip(spans, chars):
    if ch == "|": per.append(cur); cur = []
    else: cur.append(sp)
per.append(cur)
conf = [(w, float(np.mean([s.score for s in c])), c[0].start * fr, c[-1].end * fr) for w, c in zip(words, per)]
k = 0
for l in lines:
    n = len(spoken(l)); w, cf, s, e = conf[k + n - 1]
    print(f"line end  {w:12s} conf {cf:.2f}  {s:6.2f}-{e:6.2f}")
    k += n
bad = [(w, round(cf, 2), round(s, 2)) for w, cf, s, e in conf if cf < 0.35]
print("LOW CONFIDENCE:", bad or "none")

hop = 160; frm = a[: len(a) // hop * hop].reshape(-1, hop)
db = 20 * np.log10(np.sqrt((frm ** 2).mean(1)) + 1e-9)
S = np.abs(np.fft.rfft(frm * np.hanning(hop), axis=1)) ** 2
hf = 10 * np.log10(S[:, np.fft.rfftfreq(hop, 1 / 16000) > 4000].sum(1) + 1e-12)
thr, hthr = np.percentile(db, 90) - 25, np.percentile(hf, 20) + 10
quiet = (db < thr) & (hf < hthr)
runs, run = [], 0
for i, q in enumerate(quiet):
    if q: run += 1
    else:
        if run * 0.01 > 0.2: runs.append((round((i - run) * 0.01, 2), round(run * 0.01, 2)))
        run = 0
print("SILENCES > 0.2 s:", runs or "none")
print("LEAD-IN at frame 0: %.2f s" % (np.argmax(~quiet) * 0.01))
