"""039 v2 (cut-timing-hard-rules): wav2vec2 forced alignment of every picked take on the RAW voice, so starts/ends come from
the audio, not whisper. Writes align.json: per line, word spans [w, s, e] in raw seconds + the alignment score.
Also prints a literal (greedy CTC) read of each window, and scores alternative texts for unclear lines.
Run with the torch env: <torch-python> -I align_039.py"""
import json, re
import torch, torchaudio
import torchaudio.functional as F

B = torchaudio.pipelines.WAV2VEC2_ASR_LARGE_LV60K_960H
model = B.get_model().eval()
LAB = B.get_labels()
IDX = {c: i for i, c in enumerate(LAB)}
wav, sr = torchaudio.load("voice_16k.wav")
assert sr == 16000

# (window start, window end, text). Windows hug one take; extra words at the edges are included in the text so the
# alignment never has to squeeze unrelated speech into our first/last word.
LINES = [
    (20.9, 24.5, ["here's my most expensive mistake as a cto", "here's my most expensive mistake as a c t o"]),
    (47.0, 50.3, ["our hosting bill should be anywhere from twenty to thirty bucks"]),
    (58.0, 60.35, ["and this month it was"]),   # earlier take: the last one (60.68) is 9 dB muffled (cut.py refilm check)
    (62.7, 64.6, ["one hundred twelve dollars", "one hundred and twelve dollars", "a hundred and twelve dollars"]),
    (70.9, 74.4, ["i'm a vibe coder so i have absolutely no idea what i'm doing"]),
    (82.9, 88.1, ["first i pushed way too many updates and way too many new features in a single month"]),
    (99.8, 107.3, ["then i had a bot check all seven thousand of our pages in our website every single hour to see if google found them"]),
    (116.3, 120.5, ["that is one hundred sixty thousand checks every single day", "that is a hundred and sixty thousand checks every single day", "that's one hundred and sixty thousand checks every single day"]),
    (132.4, 137.5, ["so before you launch anything just make sure there is a budget alert system"]),
    (144.0, 147.4, ["cheap lesson but it could have been so much worse"]),
]

def greedy(em):
    ids = em.argmax(-1).tolist(); out, prev = [], None
    for k in ids:
        if k != prev and LAB[k] != "-": out.append(LAB[k])
        prev = k
    return "".join(out).replace("|", " ").lower()

res = []
for s0, e0, texts in LINES:
    x = wav[:, int(s0 * sr): int(e0 * sr)]
    with torch.inference_mode():
        em, _ = model(x)
    em = torch.log_softmax(em, -1)
    fr = (e0 - s0) / em.shape[1]                       # seconds per emission frame (~0.02)
    best = None
    for text in texts:
        chars = "|".join(re.sub(r"[^a-z' ]", "", text).split()).upper()
        tok = torch.tensor([[IDX[c] for c in chars]], dtype=torch.int32)
        ali, sc = F.forced_align(em, tok, blank=0)
        score = float(sc[0].sum()) / len(chars)
        spans = F.merge_tokens(ali[0], sc[0].exp())
        words, cur = [], []
        for sp, ch in zip(spans, chars):
            if ch == "|":
                if cur: words.append(cur); cur = []
            else: cur.append(sp)
        if cur: words.append(cur)
        ws = [[w, round(s0 + c[0].start * fr, 3), round(s0 + c[-1].end * fr, 3)] for w, c in zip(text.split(), words)]
        print(f"  {score:7.3f}  {text}")
        if best is None or score > best["score"]: best = {"text": text, "score": score, "words": ws}
    print(f"{s0:7.2f}-{e0:7.2f} heard: {greedy(em[0])}")
    print("        ", " ".join(f"{w}[{s:.2f}-{e:.2f}]" for w, s, e in best["words"]))
    res.append(best)
for s0, e0 in [(25.0, 37.0), (37.5, 47.0), (50.3, 60.4), (64.6, 71.0), (75.0, 83.0), (88.0, 99.8), (107.5, 116.3), (120.5, 132.4), (137.5, 144.0), (147.4, 149.0)]:                            # the run whisper left empty: what is it?
    with torch.inference_mode(): em, _ = model(wav[:, int(s0 * sr): int(e0 * sr)])
    print(f"{s0}-{e0} literal: {greedy(em[0])}")
json.dump(res, open("align.json", "w"), indent=1)
