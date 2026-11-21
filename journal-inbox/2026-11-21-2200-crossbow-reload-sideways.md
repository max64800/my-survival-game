# Crossbow reload round 3: bow across the chest, bolt from the belt (chat 18, dwarf-animations)

**What we did:** Owner: the hands still sat in the wrong place, and suggested the bow should point to his left and he should put a bolt at the end of it. New Reload (2.6 s) in `crossbow_ik_bake.gd`: bow across his chest pointing to his left (SIDE_W/SIDE_F), left hand under the fore-end, then to a belt spot (new "from the left shoulder" key, so the hand can leave the bow), then to the bolt groove near the bow's end (BOLT_END), back under the bow, then up to aim. Worst left-hand miss: 6.8 cm.

**Mistakes and hurdles:**
- My first edit of the bake script silently did not apply (wrong tab count in my search text), and the script then crashed on `pose.la`. Lesson: check the edit landed before re-running.
- Version 12 of the Moves page broke: I put "the sword's" inside a single-quoted JS string, the apostrophe ended it, the page script died (no buttons, endless loading). Found by opening the page on localhost in a test browser and reading the console. Not a download problem; compressing the data was a detour (the page now loads a gzip'd file, about 15 MB).
- I stopped the test server too early, so the owner's localhost tab closed. Owner wants localhost from now on: server stays running on port 8765 from the scratchpad moves folder.
- Owner says the hands look huge/wide. Not changed yet: dwarf hands are 1.3x thick on purpose (DwarfProportions), and the left hand's roll shows them flat toward the camera.
