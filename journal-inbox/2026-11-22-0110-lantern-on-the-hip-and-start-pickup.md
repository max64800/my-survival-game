## Nov 22: The lantern really on the hip, a lantern on the floor at the start, brighter lanterns (F612, Claude 3)

**What the owner asked:** after seeing the Hip Lantern 3D page: "it is under his armpit, not on hip". Also: pick the
lantern up at the start of a new game instead of crafting it, make the hand lantern light reach 50% further, and the
hip lantern can light about as far as the hand lantern does now. Owner's picks: hip 16 m, back 24 m, and a spare hand
lantern is made "with copper".

**What we did**
- **New hook model** (`items_gear.py` `hip_hook()`): one iron ring through the lantern's carry ring and a short folded
  leather belt loop, 12 cm instead of 20 cm. Rebuilt `lantern_hip` and `lantern_hip_hook`; check_models passed. New bag icon.
- **In the game** (`lantern.gd`): the belt loop now sits just over the belt (`BELT_ABOVE` 0.23 → 0.144). On the belt the
  lantern is drawn at 75% (`HIP_SCALE`, new `_hang()`), because a full-size lantern plus its hook is longer than a
  dwarf's leg (his belt is only about 35 cm off the ground). It goes back to full size in the hand or on the back.
- **Light:** hand 16 → 24 m, hip 13 → 16 m, back 16 → 24 m (`FULL_RANGE`, `HIP_RANGE`, new `BACK_RANGE`, tooltips use them).
- **Start:** `spawn_start_items()` also drops a lantern a step from where you wake (`start_lantern_spot()`); walking over
  it puts it in the lantern slot and it lights. The first hint is now "Pick up your Lantern from the floor".
- **Recipe:** a spare hand lantern = 2 copper ingots + 1 rootwood + 1 blue crystal at the Workbench (unlocks with copper).
- **3D page** updated (same link): the lantern hangs from the belt there too.
- Tests: the hip test now also checks the lantern's bottom clears the ground; the start test checks the lantern lies on
  the floor near you; the first-tools test checks the copper recipe. The start robot (`startcheck.gd`) walks onto it.

**Mistakes and hurdles (Claude's own)**
- **The page's lantern was in the wrong place.** The model's origin is its bottom, but the page placed it as if the
  origin were its middle, so the whole lantern sat 23 cm too high: under the armpit. Fix: put the model's top at the belt.
- **The game's lantern hung too low**, down by his feet. The first hook was too long (two rings, a bar and a tall loop,
  20 cm), and I never measured whether a lantern plus hook fits under a short dwarf's belt. The new test measures the
  lantern's real bottom.
- **The first ground test measured wrong.** It used the lantern's raw size, but the lantern sits inside the scaled
  skeleton. In the test (no `_process`) it came out stretched about 1.5× sideways. Fix: measure the drawn bottom with
  `to_global`, and call the same `_hang()` the game uses each frame.
- **The belt loop was turned the wrong way**: the belt would have gone through it sideways. The new loop's folds sit at the
  sides, so the belt runs front to back.
- `check_models.py` can't run with plain Python (it needs Blender's `bmesh`); it runs inside Blender with
  `-- items/<name>`.

**Left for the owner:** the Bright and Grand lanterns in the design (19 m and 22 m) now light less than the Back
Lantern (24 m). Ask before changing them.
