---
name: cut-timing-hard-rules
description: HARD 2026-11-01 - no dead air anywhere (start, between lines) and never clip a word's ending; verify every cut by audio, not by whisper timestamps alone
metadata:
  type: feedback
---

Max reviewed the 2026-11-01 batch (028-034) and found, in almost every video: dead air at the very start, noticeable pauses before lines ("my work just…", "I run about…", "so I was losing track", "but I couldn't remember…", "and I love it"), AND words cut off at the end ("disaster", "eventually", "supervision", "so much better", "forty seven"). "Those are tiny pauses but they are crucial for short form content." "We didn't have these issues when I was using EQT Social Media directly."

**Why:** whisper word timestamps are often late on starts and early on ends; cutting on them alone both leaves gaps and clips final syllables.

**How to apply (every short):**
- Frame 0 = first syllable of the first word (≤ 0.05 s lead-in). No silence at the start.
- Between lines: ≤ 0.12 s of silence total. Also remove any pause > 0.2 s INSIDE a line unless it's a deliberate beat Max scripted (e.g. a silence drop before a punchline, ≤ 0.35 s).
- Line ends: find the true end of speech from the AUDIO (energy/VAD on the 16 kHz track, or wav2vec forced alignment), not the whisper word end; keep +0.08–0.12 s tail after the last audible syllable. Never end a line on a whisper timestamp alone.
- Verify after cutting: forced-align (wav2vec) the cut audio against the as-filmed script and check every word is complete (especially last words and numbers), then scan the cut for any silence > 0.2 s. Fix and re-cut before rendering.
- Keep every phrase Max said that belongs to the line (e.g. "for productivity") unless it's a flubbed/repeated take.
Related: [[edit-hard-rules]], [[gold-standard-016]], [[max-paraphrases-scripts]].
