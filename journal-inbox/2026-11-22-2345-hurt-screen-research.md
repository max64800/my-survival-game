## Nov 22 — Hurt screen (F695): new options page, then big research

**What we did**
- Built a new options page `tools/ui_review/hurt_screen_options_v2.html` with 6 painted-ink hurt effects (ink rim, which side,
  blood spatter, lantern gutter, badly hurt heartbeat, full set). Each effect is drawn pixel by pixel like a Godot shader, with
  hit size, hit direction, low health and poison/burn/chill controls, and a `?t=` freeze for still pictures.
- Checked every option in a browser mid-hit (light/heavy, left/right, low health, poisoned) before showing the owner. Runs at 57 fps.
- Owner: "too much, it goes on the entire screen." Asked for a very big research on how hurt screens really look.
- Ran the research (6 helpers + a writer). Report: `docs/research/Hurt screen feedback research.md`, notes in
  `docs/research/research_notes/Hurt screen feedback research/`.
  Main finding: our current red glow already reaches 35% in from every edge; good games (Minecraft, Halo, TLOU2) show hurt
  mostly on the health bar, the character, sound and rumble, with a small or no screen effect, and separate on/off settings.
  Xbox rules: a flash over ~20% of the screen (especially strong red) is a seizure risk.

**Mistakes and hurdles**
- Claude's typo: `-(x) ** 2` is not allowed in JavaScript, so the whole page drew nothing (likely the same kind of thing that
  broke "half" of the old page). Caught it by checking the browser's error list before showing the owner.
- First version: heavy hit covered almost a third of the screen and the inner edge looked like a straight TV frame. Made it
  thinner, rounder and rougher. Even so the owner found the whole-border idea too much: lesson, a hurt effect should not
  frame the whole screen at all.
- The autopilot test game crashed on load ("mem is null", fork failures): the PC was out of memory from other running games/chats,
  not our code. Painted a cave background in the page instead.
- Many game wiki sites blocked the research helpers (402/403), so several games (Dark Souls, Terraria, Sea of Thieves...) have no
  verified facts; the report marks verified vs. not.

**Next**
- Owner picks from the report's 5 small options (ghost health bar, dwarf body flash, thin red glow for big hits only, camera
  nudge slider, sound muffle + rumble), then build into `src/ui/screen_edge_flash.gd/.gdshader` and the HUD.
