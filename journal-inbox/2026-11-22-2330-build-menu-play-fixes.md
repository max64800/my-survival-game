## Nov 22 (night, PC): build menu fixes after the owner's first play (F718-F721)

**What the owner said after trying the new build menu:** F9 god mode should let him build anything; Rootwood showed
stone pieces (Gateway, Gate Leaf, Battlement, Short Railing); Home had no pictures; the whole menu was small and hard to read.

**What we did**
- **F9 builds anything (F718):** `Builder.free_build(ps)` is true while god mode is on. The host's check skips the
  station and the cost, placing takes nothing from the bag, and flattening dips takes no dirt. The menu shows every
  card with a tick and says "F9 god mode: free, no station needed". The F9 message mentions it, and the menu redraws.
- **Right pieces per material (F719):** the Floors, Walls, Roofs and Stairs tabs only list pieces the chosen
  material can make. Material cards are always clickable now: if your piece can't be made in the new material,
  the menu picks the first one on the tab that can.
- **Home pictures (F720):** the Home pieces never had pictures, because the picture maker only cuts them from
  building previews. A new tool, `tools/model_check/decor_icon_shot.gd`, photographs each Home and Lights model on a
  see-through background (84 pictures for 42 pieces).
- **Bigger menu (F721):** the game draws menus at their pixel size, so on the owner's 1440-high screen the menu looked
  tiny. The build menu now has a zoom: screen height / 900 (so 1.5× on his screen, never smaller than now).

**Mistakes and hurdles**
- The first version of the free-build menu faked a full bag. That would have shown "you have 999" on the material
  cards. Swapped it for a simple "free mode" switch in the menu's "what's missing" check.
- The regex pass that put the zoom on every size also hit the picture helper, which is already given a zoomed size.
  It would have zoomed twice. Caught before running and fixed by hand.
- `only=` in the test runner matches file names, not test names (`fn=` is for test names). My first single-test
  runs showed "0 checks" for that reason.
