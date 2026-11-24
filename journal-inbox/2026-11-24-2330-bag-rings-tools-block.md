## Nov 24: bag fixes, rings both ways, tools that block (F828–F836, bag chat)

**What we did**
- F828: taking armour off now fills a ring too (armour 1.5 s). Click helmet, chest, legs and boots and all rings fill at the same time, not one after another. Dragging gear into or out of a gear slot also gets a ring. A hit cancels them all.
- F829: the shield stays on when you switch to a mace, or to a pickaxe, axe, hammer or shovel.
- F830: E no longer closes the bag.
- F831: weapon tips now just say "Blunt · one hand" (owner: "don't hold everyone's hand"), in a framed tip box.
- F832: blurry bag text fixed by turning on MSDF (a sharper way to draw letters) in the font import files.
- F834: worn gear weighs the same as gear in the bag.
- F836: tools block like a weaker one-hand weapon. Pickaxe/axe use right click, hammer/shovel use the middle click (their right click is busy). With a shield worn, the shield blocks. No digging while guarding.

**Mistakes and hurdles**
- `equip_time.gd` was never added to the F826 commit, so the pushed game was missing a file. Found it and committed it.
- First version of the weapon tips was too wordy; the owner asked for short.
- Little dots and an odd font on "Pierce"/"Blunt": fake bold (Godot thickening a normal font) breaks with MSDF. Fixed by using a real bold font file.
- My tools-block item took F835, but another chat already had F835 (food pictures). Renamed mine to F836, and the rename also changed two lines in the other chat's unsaved food-slot file. Put those back to F835.
- A Python "\n" wrote a real line break into hud.gd; fixed with chr(92).
- The test runner's `only=<function name>` silently runs 0 checks and still says ALL PASSED. Use `only=<file> fn=<function>`.
- The test dwarf needed `Dwarf.new()` (there is no dwarf scene file) and a stowed lantern before the shield showed.
