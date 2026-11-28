## Nov 28, 2026 (PC): Dungeon 11, The Hammerfall Works, planned (F984)

**What we did:** planned dungeon #11 (plan only, nothing built). First checked nobody else had started it (git log,
FEEDBACK files, journal inbox, other running chats) and claimed it as F984. The owner picked, from multiple-choice
questions: a "grand but wrecked" look (giant broken machines, more fallen than Emberdeep), skeletons in the works plus
the old smiths' ghosts in the lower wing, the Gearmaster (gear bolts) and the Smeltwarden (ladle splash) as the two
mini bosses, the Master of the Works as the final boss (a "Hammerfall" leap: shock ring to jump over, falling stones),
two keys that each open their own lock, the great press + flail + pendulum blades + Emberdeep's forge traps (no ore
carts), and a chain hoist way out (Emberdeep's lift reused). Wrote `docs/design/zone1-dungeons/2026-11-28-hammerfall-decisions.md`
with a full 72-space map on three levels (0, +10, -10), creatures per room and 6 build steps.

**Hurdles and mistakes:**
- The old draft was muddled: it put a two-lock gate in BOTH the Great Anvil Hall and the Masterwork Hall, and a
  "Broken Gate" room whose locks were already smashed. Fixed by keeping one two-lock gate (in the hub, north wall)
  that opens the whole second half, ending at the boss.
- The two-key door already existed in the key code (`keys_of` gives both keys, the door needs every lock), so no new
  mechanic is needed. Checked before offering choices, so the recommended option was the cheap one.
- With the hoist going UP to the entrance, the boss room has to be on the lower level, and a tall boss hall (10 m)
  needs empty space above it. Moved the second half of the works west and down (bridge, Ore Stair) so the Masterwork
  Hall sits under nothing. Checked the map with a small script: no overlaps, 3 m of rock between stacked rooms.
- The treasury had no lock of its own (a dungeon has one key door, used by the gate). Plan: reuse Hald's portcullis
  (lifts when its room is won) with a "starts shut" flag, so nobody can run past the Master to the loot.
- Claude's mistake: writing the decisions file through a shell heredoc failed (the shell choked on quote marks in the
  text). Fixed by writing the file with the file tool instead.
- Claude's mistake: claiming F984 committed the whole `FEEDBACK.md`, which also held other chats' unsaved edits.
  Harmless here (they were real feedback lines), but next time commit only your own line (`git add -p` is not
  available, so save others' edits first or ask).

**Next:** build step 1 (rooms, stairs, hoist, creatures, reused traps, two-lock gate, "Dungeon 11" dev button).
