"""039 word timings on the CUT timeline (cut_words.json) from the wav2vec alignment (align.json), mapped through edl.json.
Tokens are the as-filmed spellings; a token that is several spoken words ("$112" = "a hundred and twelve dollars") spans them."""
import json, re
AL = json.load(open("align.json")); EDL = json.load(open("edl.json"))
TEXT = {s["line"]: s["text"] for s in EDL if s["text"]}
SPAN = {"$112.": 5, "160,000": 5, "7,000": 2, "CTO.": 3}       # spoken words per token (default 1)

def to_cut(t):
    off = 0.0
    for s in EDL:
        if s["start"] - 0.03 <= t <= s["end"] + 0.03: return round(off + min(max(t, s["start"]), s["end"]) - s["start"], 2)
        off += s["end"] - s["start"]
    raise ValueError(t)

out = []
for li, text in TEXT.items():
    ws, k = AL[li]["words"], 0
    for tok in text.split():
        n = SPAN.get(tok, 1)
        grp = ws[k:k + n]; k += n
        assert grp, (li, tok)
        out.append({"w": tok, "s": to_cut(grp[0][1]), "e": to_cut(grp[-1][2])})
    assert k == len(ws), ("token/word count mismatch", li, k, len(ws))
out.sort(key=lambda w: w["s"])
json.dump(out, open("cut_words.json", "w"), indent=0)
print(len(out), "words")
print(" ".join(f'{w["w"]}@{w["s"]}' for w in out))
