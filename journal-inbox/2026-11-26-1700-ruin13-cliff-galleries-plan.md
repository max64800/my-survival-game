## 2026-11-26: Ruin 13, the Cliff Galleries: plan and shape page (F913)
- The owner liked the Mine-head's stone + wood mix ("I really liked the stone and wood") and asked for another
  stone + wood ruin. Logged as F913 (F910-F912 were taken) and claimed it right away.
- Gave 4 ideas (Cliff Galleries, Chasm Bridge-Hall, Stepped Root Farm, Underground Inn). The owner picked the
  **Cliff Galleries**: a stone hall dug into the foot of a cliff, a ledge house on a rock ledge, a watch tower on a
  high rock shelf, joined by a bridge over a crack, wooden stairs pinned to the cliff and a hanging gallery.
  Every building is stone below, wood above.
- Wrote `docs/design/ruin13/CLIFF-GALLERIES-PLAN.md` and the shape page `docs/design/ruin13/cliff_galleries_shapes.html`
  (copied from the Mine-head page; a "Show the way up" button draws the climb path). Published:
  https://claude.ai/artifact/V2YfHUTj7fmYY2L6ygprJb
- Added the Mine-head play-test lessons to `docs/design/RUIN-RULES.md` (doors rules 9-11: steps to every door, no ramp
  to a window, ladder tops level with the floor). They were not in the rules yet.
- Hurdles:
  - My first draft had the hall's wooden storey sticking out over the main door. Ruin rule 3.3 says nothing hangs
    over a door, so it now sticks out left and right instead. Same for the tower: it juts out front and left, not over
    its side door.
  - The browser helper (chrome-devtools) would not connect (timed out twice). Took the screenshots with headless
    Chrome from the command line instead (`--headless=new --use-angle=swiftshader --screenshot`), which works for
    WebGL pages.
  - The "Along the gallery" camera was too close at first (you couldn't see the gallery); pulled it back.
- Next: the owner's OK on the shapes, then step 2, `_cliff_galleries()` in the blueprint library (new chat).
