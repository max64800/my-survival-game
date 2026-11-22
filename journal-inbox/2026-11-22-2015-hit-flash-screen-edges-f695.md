## F695: the screen edges flash red when you're hit

**What we did:** The owner wanted a way to tell you got hurt without staring at the health bar — like
in a lot of games, the screen's edges flash red for a second when you take a hit. They also wanted the
edges to glow a steady colour while you're poisoned (green), burning (orange), or chilled (blue).

Taught `Vitals` (the script that tracks a dwarf's health/stamina/hunger/thirst) to shout a signal —
think of a signal as a shout anyone nearby can listen for — called `damaged`, but only when a *real*
hit lands (a sword, a fall, a trap). Poison and burning already hurt you a little bit every tick, and
that happens inside a different, lower-level piece of code that skips the normal "take damage" function
entirely — so it never triggers the shout, and the screen doesn't flash nonstop while you're poisoned.

Built a new picture-over-the-whole-screen (`ScreenEdgeFlash`) that listens for that shout. It uses a
small painted effect (a "shader," a tiny program that colors pixels) to glow just the screen's edges,
like a vignette. A hit makes it flash red and fade over about 1.4 seconds — harder hits flash brighter.
No fresh hit, and you're poisoned/burning/chilled? It glows that status's colour steadily instead. A
fresh hit always wins over the status glow, so a hit never gets lost under an existing poison glow.

**Hurdles:**
- The owner's to-do list used the *old* item numbers from before another PC session's renumbering
  (because two Claude sessions share this PC and had each already used F682-F689 for other things).
  Read `docs/HANDOVER-2026-11-22-evening.md` first and found the real mapping: this item is **F695**,
  not F682. Had to translate every number in the owner's message before starting anything.
- While testing (launching a muted, tagged game to check nothing broke), the game briefly failed to
  compile `cave_maker.gd`/`world.gd`/`main.gd` right as it started, then recovered and ran fine. That's
  another Claude session editing those exact files on this shared PC at that exact moment — not
  something I broke. Confirmed it was unrelated by checking `git blame` (none of those files are mine)
  and by seeing the test run `test_edge_flash.gd` (the one I wrote for this change) pass cleanly on its
  own, every time.
- Also saw a pre-existing, unrelated error spam every half-second ("Invalid access to property or key
  'mossy'" in `MapData.reveal`) from another session's in-progress Fungal Jungle biome work. Left it
  alone — not mine to fix, and not something the owner mentioned.
- Editing `FEEDBACK.md` to mark F695 fixed landed safely, but a *different* concurrent session's own
  commit (for an unrelated Foreman-boss fix) swept up my FEEDBACK.md edit into their commit a few
  seconds later, because they staged the whole working tree rather than just their own files. The text
  itself is correct and now safely in the project's history either way, so nothing needed fixing — but
  it's a reminder that on a shared PC, the longer an edit sits unstaged, the more likely another
  session's broad `git add` scoops it up. Committed my own code files right away afterward, touching
  only my own paths, to avoid the same thing happening to them.

**Checked:** 5 new automated tests (`tests/test_edge_flash.gd`) all pass — a real hit shouts once with
the right amount, poison ticking stays silent, god mode doesn't flash, the flash strength caps and fades
on schedule, a small new hit never dims an already-brighter one, and the status glow only shows once the
hit-flash has fully faded. Ran the whole test suite once after. Also booted a real, muted, tagged test
game (`claude=hit_flash_edges seed=42`) to watch it load and run with no new errors tied to my files,
then closed it.

**Next:** F701 (walk speeds up into a run smoothly), per the owner's build order.
