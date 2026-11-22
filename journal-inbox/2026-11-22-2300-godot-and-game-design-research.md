## Nov 22, 2026 (PC, late evening): black screen, full to-do list, and a deep "learn Godot + game design" research

**What we did**
- Black screen on the main monitor: it was a Claude test game (the Twin Gate speed test, `claude=twin_gate_fps`). The
  old copies had already closed; a new copy was busy measuring, so it was left alone and the owner was told how to move it.
- Looked for a chat that "learned Godot": none had. It was only feedback item F704 (discussion only).
- Built the whole to-do list from the roadmap, the zone 1 plans and the 135 open feedback items, with rough
  percentages (Zone 1 about 55%, whole game about 20-25%). Owner's reminder: 12 dungeons = 4 small (done),
  4 medium, 4 large.
- Owner's new job (F704): research Godot and game design as deeply as possible. 5 helpers researched in parallel
  (speed, AI workflow + co-op + Steam, fight and movement feel, guiding players + dungeons, sound + playtests + scope +
  Next Fest), then one helper wrote the report: `docs/research/reports/Godot and game design lessons.md`
  (notes in `docs/research/research_notes/Godot and game design lessons/`).

**Mistakes and hurdles**
- My first chat search matched almost every chat, because every handoff prompt contains words like "learn". Fixed by
  searching only for the owner's exact kind of wording, which found F704.
- Python printing crashed twice on Windows (an empty path split, then the "→" character). Fixed with a safer split
  and `PYTHONIOENCODING=utf-8`.
- The helpers could not read members-only GDC talks, so many numbers are from wikis or articles. The report tags each
  claim Sourced / Secondary / Guess. The report writer caught a helper's mistake: dodge invincibility frames from a
  wiki were counted at 30 FPS, so "10-13 frames" really means about 0.3-0.4 s, not 0.17-0.2 s.
- Not yet added to FEEDBACK.md: crouching, medium armor, new dwarf heads, music, voice lines, the 12-ruin goal
  (waiting for the owner's OK to add them as new F-numbers).
