"""Video 039 "My most expensive mistake as a CTO" (Downloads/IMG_4334.MOV) edit plan -> edit.json (Remotion "Edit60").
kit11 day. "Ember" palette: coral -> rose cards with gold accents. Warm like the orange/yellow print on his black tee, it pops
off the white walls, and it reads as a money alarm.
Captions: die-cut stickers (kit8 StickerCaptions, 016/031 style, slots y 1420/1515/1610).
ONE glass card (src/b1108/b039.tsx) morphs through the story:
  Vercel bill $112 (frame 1, result first)  ->  bill: "should be $20-30" chip, total counts $30 -> $112 on "a hundred and twelve dollars"
  ->  code window + "Vibe coder" / "No idea" chips  ->  Vercel deployments scrolling fast + "In 1 month" chip
  ->  bot pings | 7,000 pages counter | Google tile, "Every hour" + "Found yet?"  ->  7,000 pages x 24 a day = 160,000+ checks
  ->  Vercel Spend Management: budget alert toggles on  ->  bookend bill $112 + "Cheap lesson" + "Alert on".
Behind-head word: "EXPENSIVE" on the hook (one only, see below)."""
import json
import subprocess
from pathlib import Path

from PIL import ImageFont

HERE = Path(__file__).parent
ROOT = HERE.parent.parent
words = json.load(open(HERE / "cut_words.json"))
faces = json.load(open(HERE / "faces.json"))
frames = int(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v", "-count_frames", "-show_entries",
                                      "stream=nb_read_frames", "-of", "csv=p=0", str(ROOT / "editor/motion/public/v4334/cut.mp4")]).decode().strip().rstrip(","))
VIDEO_END = round(frames / 30, 2)
DUR = round(VIDEO_END - 1 / 30, 2)     # never freeze the end: stop on the cut's last frame (the cut keeps a ~0.1 s tail)

def at(word, near):
    c = [w for w in words if w["w"].strip(",.?!").lower() == word.strip(",.?!").lower()]
    w = min(c, key=lambda w: abs(w["s"] - near))
    assert abs(w["s"] - near) < 0.8, (word, near, w)
    return w["s"]
def end_of(word, near):
    c = [w for w in words if w["w"].strip(",.?!").lower() == word.strip(",.?!").lower()]
    return min(c, key=lambda w: abs(w["s"] - near))["e"]

PAL = {"a": "#FF7A45", "b": "#E8366B", "c": "#FFB199", "gold": "#FFC857", "gold2": "#F4A23A", "ink": "#1A1222", "mute": "#6B6275",
       "glow": ["#FF7A45", "#E8366B", "#FF9F6E", "#F4A23A"]}
INTER = str(ROOT / "editor/models/fonts/Inter-800.ttf")

# ---------- layout: drop the video under the gradient band just enough that the tallest card fits ----------
X, TOP, HAIR, CW = 540, 262, 120, 900
tops = sorted(cy - h / 2 for tt, cx, cy, w_, h in faces if cx is not None)
p10 = tops[len(tops) // 10]
SHIFT = int(max(120, min(250, TOP + 330 + 24 + HAIR - p10)))
print("face top p10", p10, "-> SHIFT", SHIFT)

# ---------- die-cut sticker captions ----------
EM = {"expensive", "CTO.", "bucks.", "$112.", "vibe", "coder", "idea", "updates", "features", "bot", "7,000", "hour", "Google",
      "160,000", "budget", "alert", "Cheap", "worse."}
COLS = ["#E8366B", "#0A84FF", "#FF7A00", "#34C759", "#AF52DE"]
stickers, cur, pile, ci, pile_end = [], [], 0, 0, []
def flush():
    if cur: stickers.append({"from": round(cur[0]["s"], 2), "pile": pile, "words": list(cur)}); cur.clear()
for i, w in enumerate(words):
    ww = dict(w)
    if w["w"] in EM: ww["col"] = COLS[ci % len(COLS)]; ci += 1
    if cur and (len(" ".join(x["w"] for x in cur + [ww])) > 17 or w["s"] - cur[-1]["e"] > 0.45): flush()
    cur.append(ww)
    if w["w"][-1] in ",": flush()
    if w["w"][-1] in ".?!":
        flush()
        nxt = words[i + 1]["s"] if i + 1 < len(words) else DUR
        pile_end.append(round(min(nxt - 0.02, w["e"] + 0.6), 2)); pile += 1
flush()
if len(pile_end) < pile + 1 and stickers and stickers[-1]["pile"] == pile: pile_end.append(DUR)
pile_end[-1] = DUR
F68 = ImageFont.truetype(INTER, 68)
for s_ in stickers:   # a sticker (68 px + 30 px die-cut rim) must stay inside x 80..900 around its slot centre (~500)
    wd = F68.getlength(" ".join(w["w"] for w in s_["words"])) + 60
    assert wd <= 800, ("sticker too wide", [w["w"] for w in s_["words"]], round(wd))

# ---------- the glass card ----------
def S(t0, h, scene):
    return {"at": round(t0, 2), "x": X, "y": TOP, "w": CW, "h": h, "scene": scene}
L2, L3, L4, L5, L6, L7, L8, L9 = (at("Our", 3.15), at("And", 6.05), at("I'm", 9.55), at("First", 12.64), at("Then", 17.64), at("That", 24.7),
                                  at("So", 28.4), at("Cheap", 32.73))
t112 = at("$112", 7.81)
DEPLOYS = ["new feature: lead finder", "update: homepage hero", "new feature: listings map", "update: fix mobile menu",
           "new feature: price alerts", "update: new fonts", "new feature: blog pages", "update: SEO titles"]
states = [
    S(0.0, 300, {"kind": "b039_bill", "label": "Vercel · Hosting bill", "total": 112, "tag": "Over budget", "tagAt": 0.25}),
    S(L2 - 0.1, 300, {"kind": "b039_bill", "label": "Vercel · This month", "total": 112, "from": 30, "countAt": t112,
                      "expect": "$20–30", "expectAt": at("20", 4.78), "tag": "Over budget", "tagAt": t112 + 1.1}),
    S(L4 - 0.1, 300, {"kind": "b039_vibe", "label": "Me", "title": "CTO", "at": L4, "chip": "Vibe coder", "chipAt": at("vibe", 9.82),
                      "q": "No idea", "qAt": at("no", 11.41)}),
    S(L5 - 0.1, 330, {"kind": "b039_deploys", "label": "Deployments", "at": L5, "rows": DEPLOYS, "speed": 320,
                      "featAt": at("single", 16.74), "feat": "In 1 month"}),
    S(L6 - 0.1, 330, {"kind": "b039_bots", "label": "My bot", "at": at("bot", 18.28), "countAt": at("7,000", 19.46), "count": 7000, "unit": "pages",
                      "hourAt": at("hour", 22.73), "hour": "Every hour", "googleAt": at("Google", 23.73), "ask": "Found yet?"}),
    S(L7 - 0.1, 290, {"kind": "b039_math", "a": "7,000 pages", "aAt": L7, "b": "24 a day", "bAt": L7 + 0.25, "res": 160000,
                      "resAt": at("160,000", 25.04), "unit": "checks a day"}),
    S(L8 - 0.1, 324, {"kind": "b039_alert", "title": "Spend Management", "at": L8, "row": "Budget alert", "budget": "$30",
                      "onAt": at("alert", 31.66), "allAt": at("launch", 29.03), "all": "Before launch"}),
    S(L9 - 0.1, 300, {"kind": "b039_bill", "label": "Vercel · Hosting bill", "total": 112, "tag": "Cheap lesson", "tagAt": L9, "gold": True,
                      "alert": "Alert on", "alertAt": at("could", 33.83)}),
]
assert 7000 * 24 >= 160000, "the 160,000+ on screen must agree with 7,000 pages x 24 checks"

# text-fit checks with the real Inter 800
def fits(text, size, room, what):
    wd = ImageFont.truetype(INTER, size).getlength(text)
    assert wd <= room, (what, text, round(wd), room)
RIGHT = CW - 36 - 150 - 34 - 36                      # bill right column
fits("$112", 124, 330, "bill total")
for st in states:
    sc = st["scene"]
    if sc["kind"] == "b039_bill":
        fits(sc["label"], 26 * 1.15, RIGHT, "bill label")      # uppercase + 2.2 tracking ~ +15%
        chips = (ImageFont.truetype(INTER, 28).getlength(sc.get("tag", "")) + 28 + 10 + 45) + (
            ImageFont.truetype(INTER, 28).getlength(sc["alert"]) + 28 + 10 + 45 + 16 if sc.get("alert") else 0)
        assert chips <= RIGHT, ("bill chips", round(chips), RIGHT)
        if sc.get("expect"): fits(sc["expect"], 30, RIGHT - 330 - 18 - 42, "expect chip")
fits("CTO", 64, CW - 36 - 330 - 34 - 36, "vibe title")
fits("Vibe coder", 30, CW - 36 - 330 - 34 - 36 - 46, "vibe chip")
fits(max(DEPLOYS, key=len), 28, CW - 72 - 36 - 30 - 16 - 110 - 16, "deploy row")
fits("7,000", 100, 330, "bot counter")
fits("160,000+", 108, CW - 72 + 8 * 4.5, "math result")   # -4.5 px tracking per glyph
fits("7,000 pages", 30, (CW - 72 - 60) / 2 - 90, "math chip")
fits("Spend Management", 40, CW - 72 - 72, "alert title")
fits("Budget alert", 34, CW - 72 - 44 - 56 - 92 - 120 - 54, "alert row")

for i, st in enumerate(states):
    end = states[i + 1]["at"] if i + 1 < len(states) else VIDEO_END
    tp = sorted(cy - h / 2 for tt, cx, cy, w_, h in faces if cx is not None and st["at"] + 0.3 <= tt < end)
    room = (tp[len(tp) // 10] if tp else 500) + SHIFT - HAIR - 24 - TOP
    st["scale"] = round(max(0.82, min(1.0, room / st["h"])), 3)
    assert st["h"] * st["scale"] <= room + 2, ("card over his head", st["scene"]["kind"])
    print(f'{st["scene"]["kind"]:13s} h {st["h"]}  room {room:.0f}  scale {st["scale"]}')
glass = {"from": -0.6, "to": round(DUR + 0.5, 2), "states": states, "pal": PAL}

# ---------- big words behind his head: just under the card, only the top of the hair covers their bottom ----------
def behind_word(text, t0, t1, state, size):
    win = [cy - h / 2 for tt, cx, cy, w_, h in faces if cx is not None and t0 - 0.2 <= tt <= t1]
    hair = min(win) + SHIFT - HAIR
    card_bottom = TOP + state["h"] * state["scale"]
    y = round(max(card_bottom + 24, hair + 25 - size * 0.8))
    assert ImageFont.truetype(INTER, size).getlength(text) * 0.955 <= 1000, ("behind word too wide", text)
    print(f"{text}: top {y}, bottom {y + size * 0.8:.0f}, hair top {hair:.0f}")
    return {"from": round(t0 - 0.1, 2), "to": round(t1, 2), "at": round(t0, 2), "text": text, "size": size, "y": y}
behind = [behind_word("EXPENSIVE", at("expensive", 0.98), round(L2 - 0.2, 2), states[0], 150)]
behind[0]["y"] = TOP + states[0]["h"] + 24      # QA still 2.2 s: he leans up into the word, so sit it right under the card (hair covers ~1/3)
# no second word: on the deploy line the card is 330 tall and his hair sits at y ~642, so a word there would be >70% hidden

# ---------- smooth push-ins (kit11: eased, no punches), gentle release at sentence starts ----------
eyes = {}
for t_, cx_, cy_, w_, h_ in faces:
    if cx_ is not None: eyes[t_] = (cx_, cy_ - 0.2 * h_)
def eye_at(t):
    sel = [v for k, v in eyes.items() if abs(k - t) <= 0.3] or [eyes[min(eyes, key=lambda k: abs(k - t))]]
    return round(sum(p[0] for p in sel) / len(sel)), round(sum(p[1] for p in sel) / len(sel)) + SHIFT
PUSH = [(0.0, 1.02, 0.6), (at("expensive", 0.98), 1.07, 1.0), (L2, 1.02, 0.6), (t112, 1.10, 0.8), (L4, 1.02, 0.6), (at("no", 11.41), 1.07, 0.8),
        (L5, 1.02, 0.6), (at("way", 13.75), 1.07, 1.0), (L6, 1.02, 0.6), (at("hour", 22.73), 1.07, 0.9), (L7, 1.02, 0.5),
        (at("160,000", 25.04), 1.10, 0.9), (L8, 1.02, 0.6), (at("alert", 31.66), 1.07, 0.8), (L9, 1.03, 0.6), (at("worse", 35.2), 1.08, 0.8)]
beats = [{"at": round(t0, 2), "zoom": z, "ox": eye_at(t0)[0], "oy": eye_at(t0)[1], "dur": d} for t0, z, d in PUSH]

# ---------- sound: signature = coins + counter rolls + notification pings; low_hit only on $112 and 160,000 ----------
SND = []
def sfx(t, s, v): SND.append({"t": round(max(0, t), 2), "s": s, "v": v})
b0, b1, vb, dp, bt, mt, al, b9 = [s["scene"] for s in states]
sfx(0.0, "coin", 0.2)                                     # a real sound in frame 0
sfx(b0["tagAt"], "glitch", 0.12)
sfx(behind[0]["at"], "impact_b", 0.16)
for i, st in enumerate(states[1:]): sfx(st["at"] - 0.05, ["swish_b", "whoosh_c", "swish", "whoosh_b", "swish_c", "whoosh", "swish_b"][i], 0.18)
sfx(b1["expectAt"], "pop_b", 0.16)
sfx(b1["countAt"], "count_roll", 0.2); sfx(b1["countAt"] + 1.1, "low_hit", 0.26); sfx(b1["countAt"] + 1.12, "coin", 0.16)
for j in range(4): sfx(vb["at"] + j * 0.3, "keys", 0.1)
sfx(vb["chipAt"], "pop_c", 0.16); sfx(vb["qAt"], "bubble", 0.16)
for j in range(9): sfx(dp["at"] + 0.2 + j * 0.45, "tick_b" if j % 2 else "tick", 0.09)
sfx(at("way", 13.75), "stamp", 0.12); sfx(dp["featAt"], "pop_b", 0.16)
sfx(bt["at"], "notif", 0.14); sfx(bt["countAt"], "count_roll", 0.16); sfx(bt["hourAt"], "tick", 0.16); sfx(bt["googleAt"], "pop_c", 0.16)
sfx(mt["bAt"], "click", 0.16); sfx(mt["resAt"], "count_roll", 0.2); sfx(mt["resAt"] + 1.2, "low_hit", 0.24)
sfx(al["allAt"], "pop_b", 0.14); sfx(al["onAt"], "click", 0.2); sfx(al["onAt"] + 0.15, "notif", 0.18)
sfx(b9["tagAt"], "shine", 0.18); sfx(b9["alertAt"], "ding_b", 0.16)
SND.sort(key=lambda s: s["t"])

props = {"duration": DUR, "video": "v4334/cut.mp4", "person": "v4334/person.webm", "chunks": [], "captionStyle": "stickers",
         "stickers": {"stickers": stickers, "pileEnd": pile_end, "size": 68,
                      "slots": [{"x": 470, "y": 1420, "rot": -4}, {"x": 530, "y": 1515, "rot": 3}, {"x": 480, "y": 1610, "rot": -2}]},
         "glass": glass, "glassBehind": behind, "pal": PAL, "aurora": {"solid": SHIFT + 12, "fade": SHIFT + 170},
         "beats": beats, "blur": [], "nocap": [], "elements": [],
         "split": [{"from": -1, "to": round(DUR + 0.6, 2), "shift": SHIFT}], "splitUnder": True, "sfx": SND}
json.dump(props, open(HERE / "edit.json", "w"), indent=1)
print(len(stickers), "stickers |", "video", VIDEO_END, "dur", DUR, "|", len(states), "card states,", len(beats), "push-ins,", len(SND), "sounds")
