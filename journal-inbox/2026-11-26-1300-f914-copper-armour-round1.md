## Nov 26: Copper armour from the leather, round 1 (F914)

**What we did**
- Built ONE recipe for every metal armour set, inside `tools/asset_forge/builds/dwarf_armor.py` (the `SETS` table).
  A metal set takes the leather armour's own shapes (so it always fits the dwarf) and lays riveted metal plates on top:
  gaps between plates, a raised rim, a slight dome, rivets in the corners. It also makes him bulkier (about 1 cm),
  makes the shoulder guards a third bigger and the fleece fatter. A new set = one new entry (colours, metal picture, shine).
- Owner's picks before building: plates on leather, keep the fleece, medium bulk, 3 pieces (helmet, chest, boots; leg armour later).
- Made the copper set (`assets/characters/dwarf/armor_copper.glb`) and put it in the game as look "copper" (`DwarfRig.ARMOR_FILES`).
  The fit test now checks both leather and copper (`test_hand_built_armor_fits_the_body`): passes.
- 3D page: leather dwarf next to copper dwarf (https://claude.ai/artifact/VCGQWjnc9oM23zuAiCZqFo).

**Owner's verdict:** "doesn't look like metal, it looks like a recolor leather". Wants: hands and feet covered (metal gloves,
full metal boots), a helmet that also covers the eyes and nose with only the beard sticking out, and a better metal look.
That is round 2.

**Mistakes and hurdles**
- **My claim commit took another chat's files (Claude's own).** Another chat had bronze files already staged ("added" but
  not committed). My `git commit` for the F914 claim line swept them in and pushed them (0f2ad430). It was the bronze
  round-2 work the owner had already seen, so I left it. Lesson: run `git diff --cached --stat` before every commit.
- **A name clash (Claude's own):** the recipe was called `S`, but the helmet code has its own `S`. Renamed it `RC`.
- **A crash in the first test build (Claude's own):** I used a number list where Blender wanted one number (the boot's
  rivet height). Fixed by using the plain height.
- **Round 1 looked like blotchy dark leather.** The painting step always saves a dull, leather-like material. Fix: the recipe
  now gives metal pieces real shine (metal 0.6, rough 0.42) after painting, a brighter copper, and the metal picture at
  half strength. Better, but the owner still sees leather: the plates follow the soft, puffy leather shapes. Round 2 needs
  hard, flat metal shapes, not just paint.
- **Blender ran out of memory once** (a game and three Godot windows were open). The retry worked.
- **The page's copper file was 16.1 MB, over the 16 MB limit.** Split its data into two text files the page joins.
  I also first wrote my own picture-shrinking tool, then found `pack_page_gltf.py` already does it, and deleted mine.
- **I couldn't open the live page in Chrome** (the browser link timed out three times). Checked the same page in a hidden
  Chrome on this PC instead: it caught a "Loading" text that never went away, garbled "…" letters, dwarfs standing
  too close, and close-up buttons aimed between them. All fixed.
- **The test said "0 checks".** I gave `only=` a test function's name; it wants the file (`only=test_dwarf fn=<function>`).
