## 2026-11-27 19:15 — Copper helmet + chest approved; picture-made test removed (F914)

**What we did**
- The owner picked the black edges. They said the gold-brown was "too golden, too brown" and wanted more gold, so Claude made a truer gold (yellower, with a soft sheen) for the 3D page only. The game keeps black.
- The owner OK'd the copper helmet and chest. Claude removed the picture-to-3D test: the armor_copper_picture3d files, the two scripts that made it, its CREDITS row, the "pic3d" look in DwarfRig (plus the shirt-darkening that only it used), and the side-by-side in the shot tool. CLAUDE.md rule 0 now says the test is over and rule 1 (hand-built only) stays.

**Mistakes and hurdles**
- Fully matte gold looks tan or khaki in the game light. Gold only reads as gold with a little shine (metal 0.6, rough 0.5) and more yellow than red.
- Removing the old picture files from the 3D page was refused (not read this chat), so they still sit on the page unused.

**Checks:** armour tests pass. test_dwarf still has the same 5 failures as all day (braids, aim, stun meter, camera, fists). They don't involve the armour and come from other chats' work in progress.
