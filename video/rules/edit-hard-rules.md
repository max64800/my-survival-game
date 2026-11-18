---
name: edit-hard-rules
description: Max's non-negotiable edit rules from the Palm long-form v2 review (2026-10-11) — tight sentence-level cuts, no breaths/dead air/bad takes, b-roll never slowed, graphics always on screen, numbers count up and never overflow
metadata:
  type: feedback
---

Max reviewed long-form v2 (2026-10-11) and stopped at 4:49 with 27 issues: "they are repeating over and over… learn from your mistakes… I expected a lot better". The rules:

**Cutting (the biggest failure):**
- Cut at SENTENCE level from an accurate transcript (faster-whisper medium.en, or better, on the clean voice). Never cut whole paragraphs with their retakes inside.
- Remove every breath, hesitation and dead air. Close word gaps over about 0.3 s, and use about 0.15-0.25 s between sentences.
- Remove ALL bad takes: false starts, restarts, partial sentences, repeated words ("buys… buys"), and phrases repeated across an angle switch. Also remove moments where he leans in or starts the teleprompter.
- The first second must be clean (no false start before the first word).
- Listen-check every cut point: no clipped words and no doubled words.

**Camera:**
- Use the side angle sparingly and briefly (about 2-3 s, mainly to hide a jump cut). It must never run long.
- Switch angles only on a sentence boundary. No rough mid-word angle cuts.
- Never cut to the same angle again right after a short shot.

**B-roll:**
- NEVER slow down B-roll; it visibly looks bad. Use clips at 1x. If a clip is too short, use a shorter slot or chain another clip.
- Consecutive B-roll shots hard-cut into each other. Never flash back to Max for a split second between two B-roll shots (merge gaps under about 1.5 s).
- Screen recordings (the eqt.ae map) are never cropped or pushed in. Show the full frame.

**Graphics:**
- Every stretch of video has a motion graphic or B-roll. No 5+ s stretch of plain talking head, including the intro.
- Numbers must visibly CLIMB (count up) and start counting when he says the number, not before.
- Text and numbers must never overflow their boxes. Auto-size them to fit, keep them clear of the corner camera, and never let shapes touch labels.
- No jittery text (no continuous scale drift on text pages).
- When he names a count ("five price bands"), show that many shapes appearing, then morph them into the chart.
- Diagrams must be simple and tasteful. The frond "shape" diagram looked like a phallus, so avoid elongated rounded shapes.

**Why:** these are basic editing standards; repeating them wastes his time and trust.

**How to apply:** before any render, run automated checks:
- word gaps;
- duplicated phrases;
- B-roll rate == 1;
- no gaps under 1.5 s between B-roll shots;
- text fits its box;
- graphic coverage.

Then QA the render against this list.

Related: [[qa-every-render]], [[longform-youtube-setup]], [[broll-rules]], [[motion-flow-rules]].

**Never freeze the end (Max, 2026-10-26):** the video stops ~0.15 s after the last spoken word. No held or frozen last frame (a hold past the end of the take freezes it). Also trim room tone after the last word of every line (cut to the real voice end, not whisper's padded end).

**Before delivery: repeat + false-start scan (Max, 2026-11-15, "keep it in the rules"):** after the final render, transcribe the WHOLE rendered audio word by word (`work/LF07/qa_transcribe.py`, medium.en, 25 s windows) and scan it (`qa_repeats.py`) for ANY repeated word or phrase ("at Fairmont… at Fairmont" got through in ep 7 v2) AND for false starts before cuts: a phrase cut off right before a cut where the next take starts differently ("if you want to | if you want the most space"). Whisper hides restarts, so also run a literal wav2vec2 listen (`w2v_any.py`) on every sentence built from more than one piece. Every hit is fixed (pin the clean take in force.json) or shown to be in the script before delivery.

**Talking-head card fills edge to edge, no jump at cuts (Max, 2026-11-15):** the corner/side camera card must be filled by the video with no visible strip on any side, and the framing must not move at a cut. In code: clamp the video offset so it always covers the card (tx, ty <= 0 and >= card size - video size), use ONE face position for every shot in card mode, and no slow drift inside the card (it resets at each cut). Check: render stills 0.05 s before and after at least 10 cuts that fall inside a card and look at the top edge at full size.
