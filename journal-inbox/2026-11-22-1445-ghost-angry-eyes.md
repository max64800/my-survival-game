## 2026-11-22: angry teardrop eyes for every ghost (F681)

**What we did:** The owner drew the eye shape they wanted on a screenshot: an angry teardrop, round at the bottom with a point going up and out. Every ghost (Drifting Shade, Wrathful Shade, Bearded Shade and the Grey Warden boss) now has those eyes. They're built in the Blender ghost script (`tools/asset_forge/builds/ghost_body.py`, `angry_eye`), then copied into the game, and the 3D page is updated.

**Hurdles and mistakes:**
- **My first try barely showed.** I built each eye from a round ball plus a tapering tube. Most of it sank inside the hood, so only tiny dots poked out. Fix: make the eye a flat "cookie-cutter" teardrop pushed a little out of the face, so the whole shape shows.
- **Too small for the clay grid.** The model is sculpted on a grid of 9 mm squares, so a small eye came out blocky. Fix: made the eyes about 30% bigger on the Wrathful and Bearded ghosts.
- **Tests broke because of another Claude's file.** A line committed seconds earlier in `src/combat/dwarf_fight.gd` (`var eff_reach := ...`) had a type Godot couldn't work out, so no game script would load. That isn't my file, so I didn't commit any change to it. I fixed it on my copy only long enough to run my tests (all 8 ghost tests pass), then put the file back exactly as it was. The other Claude still needs to fix that line.
