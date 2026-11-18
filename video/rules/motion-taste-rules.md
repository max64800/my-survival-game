---
name: motion-taste-rules
description: "HARD rules from Max scoring 110 library demos (2026-10-12) — what he loves/rejects, usage frequency caps, per-item fixes, SFX variety"
metadata:
  node_type: memory
  type: feedback
  originSessionId: db80a14d-def3-49f8-b467-bfcb8a1d4bc8
  modified: 2026-10-12T06:40:19.475Z
---

Max scored 100 motion demos + 10 caption styles on 2026-10-12 (all scores + his words: `work/library/scores-2026-10-12.json`). Rejected items (≤4) were deleted from the code; renders deleted after review. These patterns now apply to EVERY edit.

**What scores 9 (copy these qualities)**
- Graphics that EXPLAIN a process or comparison clearly: m1-09 paperwork maze (dead ends vs guide's path), m1-10 Venn overlap, m2-01 3D price bars, m2-02 floors stacking (split screen), m2-06 exploded price layers, m2-10 stairs + hopping ball, m4-12 word ladder (cream, huge Anton + mono lines, scroll), m4-16 torn-paper reveal, m4-19 myth→fact flip cards.
- Liquid/"water" transitions are loved (m1-07 ripple → water at the end, m1-15 dots flowing between circles).
- 8s: m4-01 hero word behind head, m4-02 colour scenes, m4-07 split-flap, m4-10 text-mask, m4-11 terminal for numbers, m4-13 circular badge, m4-18 highlighter, m5-08 floor plan with walking dot, m5-10 commission pie, m5-14 yield gauge, m3 UI set (06 rings, 07 filter toggles, 08 notification stack, 09 chat thread, 13 bar race, 14 line chart, 16 checklist, 17 developer rating, 18 spreadsheet, 20 KPI dashboard), m1-01/16/17/19, m2-03.

**What fails**
- "Microsoft Paint" look: code-drawn illustrations of OBJECTS (towers, rooms, photos, keys, doors, houses) → crude. Prefer abstract shapes, UI, typography, charts. (m5-02 key handover 1, m5-16 SOLD photo 1, m5-09 tower 5, m5-18 rooms "paint".)
- 3D novelty not tied to the point (m2-07 house assembling, m2-08 key/door, m2-14 cubes RENT→OWN, m2-15 dominoes, m2-17 scale, m2-18 elevator, m2-20 ribbon: all 1/10). 3D only when it makes a NUMBER or STRUCTURE clearer (bars, floors, layers, steps).
- Low visibility: thin, small, low-contrast, particles (m4-05 3/10; captions c2-05/06). Too simple / no idea (m5-13 equation chips 3, m1-12 hourglass 1). Serif+script stack (m4-09) rejected.
- Things blending: boxes the same colour as the background (m5-19), text over two colours with no backing (m5-20), adjacent boxes with no separator (m1-13). Always separate with contrast, a hairline or a backing plate.
- ANY collision: text touching/overlapping shapes or other text (m1-10, m1-17, m2-05, m2-12, m2-13) — he spots every one.
- Data bugs: a number changing when it shouldn't (m3-19 price changes on click), highlight starting on the wrong column (m3-04), boxes cutting off content (m3-03, m3-05, m1-02), lines not meeting their pins (m2-11), jittery/misplaced click cursors (m5-12), stepped (non-smooth) counting (m2-04).

**His face**
- Face bubbles must show his WHOLE HEAD, centred (m5-11, m2-12 "too close").
- Never put his face/eye behind a mask or letter (m4-14 zoom through the O). Text-mask video (m4-10) only as a transition, not over his face.
- Full-screen multi-option scenes (m4-02) must cut back to his face between options.

**Frequency caps (powerful pieces lose impact if repeated)**
- Max ONCE per video: 3D pieces (use 3D sparingly overall), m4-07 split-flap (areas/countries/travel), m4-08 ribbons (first part only, short), m4-15 ink blot (needs a lead-in transition), m5-04 payment plan, m5-14 yield gauge.
- 1-2 per video: m4-11 terminal (numbers / hard explanations).
- "Occasional": m4-03, m4-06, m4-17, m4-20, m5-01, m5-05, m5-06, m3-12 (hard to read fast).
- He often said "not sure where to use it": every library item needs a clear USE-WHEN trigger tied to a script line type (comparison, process, number, list, myth, location).

**Fix before first use** (from his notes): m1-10 white text over the yellow at the end · m1-13 separators · m1-17 end text touching circle · m1-02 plate cuts the magnet · m2-04 smooth counting · m2-05 boxes vs text · m2-11 route lines to pins · m2-12 face bubble + pie/text collision · m2-13 text collisions · m3-03 bigger box (circle cut) + no leading zeros while counting · m3-04 highlight starts on the right column · m3-05 bigger boxes steps 3-4 · m3-19 price must not change on click · m4-02 cut to his face between options · m4-14 nothing of his face behind the O, shorter first part · m5-11 whole head in bubble · m5-12 remove the click circle · m5-17 smaller arrow · m5-19 box colour ≠ background · m5-20 backing behind the middle text.

**Video 014 feedback (2026-10-12)**
- NO EQT logo / EQT.ae end card unless the video is one of the 1-2 weekly EQT videos ("this has nothing to do with EQT"). End on the CTA instead. (See [[content-direction]].)
- Chat-bubble captions must STACK: 3-4 rows visible, older ones move up and fade out at the top. Never show only the newest bubble.
- Graphics must not show items before he says them (the "start simple" tab showed CRM / huge website / AI app before he mentioned them, and "AI app" was never said). Every chip/row appears on its spoken word.
- Plate fonts were "quite small" from the first step to the third: main text ≥ ~44 px EFFECTIVE (after the plate's scale), labels ≥ ~32 px; prefer compact layouts that can run at scale 1.0 over big plates scaled down.

**Sound**: SFX were "pretty much the same in all of the videos". The kit now has 35 sounds (editor/sfx.py → public/sfx): pick by ROLE (movement / appear / slam / counter / success-money / build-up / paper / tech), rotate the _b/_c variants, give each video its own 2-3 signature sounds, and keep low_hit for the 2-3 biggest reveals. Never the same whoosh+pop on every event.

**Captions** (both batches, see [[motion-library-2026-10-12]]): top = c2-04 chat bubbles, c2-07 glass pills, c1-09 die-cut stickers; good = c1-03 depth pull, c1-07 behind-head, c2-08/09/10. He likes captions on a solid container (bubble, pill, sticker, tape) with a clear reading order and BIG bold words; rejects thin/light/elegant styles (serif+script, quiet-luxury one-word, marker, paper unfold), fast ones, faint "preview" words, and an SFX on every caption. Our old "levels" style is now "basic" (4/10) — don't default to it. Plan: one main caption style per video, rotating the winners; at most one accent style for a specific beat (chat bubbles for a quoted conversation, pills for a list).

Related: [[culture-video-feedback]], [[shapes-are-one-tool]], [[motion-flow-rules]], [[keep-morph-and-zoom-punches]].
