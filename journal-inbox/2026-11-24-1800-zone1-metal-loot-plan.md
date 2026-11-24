## Nov 24, 2026 — Zone 1 metal + loot plan (F697 bronze, F844)

**What we did:** Planned (no building yet) where Zone 1's metal recipes come from. Copper armour and weapon recipes move
to the ruins (fixed: 1–2 per ruin, armour in the small ruins, big weapons in the grand ones). A new ore, tin, appears in
the Zone 1 cave walls, and copper + tin make bronze. Bronze recipes go in the 12 dungeons, always the same one per dungeon,
in the owner's order (armour first). Each dungeon entrance gets a signpost with 1–3 skulls and a picture of the prize.
The owner answered four questions: ruins fixed 1–2 each, Copper Pickaxe stays free, the bronze pickaxe goes in Mossgate's
big chest, and bronze starts as recoloured copper models. Plan: `docs/decisions/2026-11-24-zone1-metal-and-loot.md`.

**Hurdles and mistakes:**
- Claude's claim commit for F697/F844 also picked up the stairs chat's unsaved F838–F840 edits in FEEDBACK.md.
  They were that chat's own correct edits, so nothing was lost, but Claude should check `git diff FEEDBACK.md` before
  committing a shared file. Fixed by checking the diff before the second commit.
- Ruin distances from the start aren't stored in one place (each ruin picks its own spot), so the ruin → recipe table goes
  by ruin size (small → armour, grand → big weapons) instead of measured distance.
- Found that the dungeon sizes (small/medium/big) already match the owner's 1/2/3 skulls exactly, so no dungeon has to move.
