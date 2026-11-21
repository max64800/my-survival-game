## Nov 21: F527, smaller cracked skulls for the skeleton miners (model chat)
- **Owner (Miner Moves page): "the heads are too big; normal size, scratches and cracks, more realistic, a bit
  scarier"** (all 3: Tunnel Rat, Lost Miner, Foreman, all 7 looks).
- **Why they were big:** `kaykit_miners.py` gave the head bone the opposite of the chest's scale on purpose, so the
  pack's big cartoon skull kept its full size. Now every head is `HEAD_SCALE` (0.56 wide, 0.64 tall, 0.62 deep) of
  the pack's: a bit narrower than tall, like a real skull. Helmet, lamp and beard pad are sized from the new head
  (`HK`), and the beard is a little narrower.
- **Cracks and scratches (`crack_skull`):** the skull's bone faces get their own picture, the creature's own bone
  paint with bold cracks painted in (a dark groove, a darker middle, a thin pale worn rim: rule 6) and three
  pick scratches. Each of the skull's 6 sides has its own square of the picture, so a crack on the forehead doesn't
  repeat on the back of the head. Cracks are placed round the skull (face, temples, back) by shooting a ray at it,
  start under the helmet's brim and run down past the eye sockets; uneven zigzags with 1-2 hairline branches.
  Every creature has its own set (`CRACKS`); every look of it gets the same cracks.
- **Picture rounds (Claude's own, before showing the owner):** (1) the cracks were hair-thin and hidden under the
  brims, invisible on the Rat: 3x wider, longer, down onto the cheekbones. (2) They looked like neat cartoon
  lightning bolts with white outlines, and the scratches looked like pale stripes: uneven zigzags, branches,
  thinner rims, darker scratch grooves. (3) The back of the smaller skull poked through the helmet dome (a pale patch
  on the Lost Miner's and the Foreman's helmets): the dome sat 2 cm too far forward (a fixed number that didn't
  shrink with the head); now it shrinks, and the dome is a bit roomier.
- **Hurdles:** Blender has no picture library (PIL), so the crack lines are drawn with numpy (thick lines, round
  ends). The model checker found 2 new problems from the smaller gear: the Lost Miner's lamp glass now sat 1.3 mm
  from the cup's rim (flicker; it now sits 4 mm forward), and the Foreman's moustache floated 3 cm off his
  smaller jaw (the beard pad now reaches forward to the locks). All 7 pass `check_models.py`.
- **Pictures for the owner:** `journey/skeleton_miners/f527_*.jpg` (before/after, 3 sides of each head, all 7
  looks). The new models are still only in Claude's scratch folder, not in the game: waiting for the owner's OK.
- **3D page "Cracked Skull Miners"** (owner asked): all 7 new looks, an old-vs-new switch, a close-up button per
  face, 11 move buttons, still until you press one. Hurdle: the page host refuses .glb files (even with a type
  given); `tools/asset_forge/pack_page_gltf.py` turns each into glTF text (.json) with the pictures at half size.
  Claude's own browser check didn't finish: the test tab closed twice in the shared Chrome.
  Owner: "Couldn't load new/tunnel_rat_grime.json". Cause: the page host blocks the 3D loader from reading the
  model's data written inside the file as text (a "data:" address). Fix: the page decodes that text itself and gives
  the loader a ready-made model in memory (version 2).

### F527 round 2 (owner: own clothes per look, black eyes, much bigger cracks, black marks on the bodies)
- **Brown shirt on every look:** the pack paints the shirt (and the Rat's cloak) a red-brown that our colour sorter
  called "leather", and leather was the same brown for all 7. Now a "shirt" kind of its own, and every look has its own
  shirt, leather and cloth colours (Rat: moss green / soot black / rust red; Lost Miner: blue / pale grey / sea green).
- **Hurdle found on the way:** the bone's shaded parts were also sorted as "leather", so arms and jaws had brown
  patches. They count as bone now.
- **Black eyes:** the glowing eye balls and the 2 dark faces inside each socket are now flat black. The material is named
  "socket", not "eye...", so the game's attack warning makes the whole body glow instead of the (black) eyes.
- **Body marks:** black cracks and 2-3-line pick scratches are drawn into the bone paint itself (wrapping round its
  edges, since it repeats over the body); the Foreman also gets dark stains. Skull cracks 1.7x wider and black.
- **Mistake:** the Lost Miner's ghost glow was one flat colour added on top, so his black scratches showed pale grey.
  Fixed by letting the glow follow the paint (black stays black).
- All 7 pass check_models; 3D page updated (version 4). Waiting for the owner's OK before the game install.

### F527 round 3 (owner: "a lot darker, they're too cheerful")
- Black helmets (the Rat's cap too) and black pick/shovel heads: a new near-black hand-painted iron ("iron_black").
- Every paint darkened by a fixed amount per kind: clothes and shirts to half, leather 0.55x, wood 0.45x, body iron
  0.65x, copper 0.6x, bone and beards about 0.65x. The Lost Miner's ghost glow went from 0.12 to 0.05.
- **Hurdle:** after the first pass the bones still looked bright in the renders (they had only been darkened 0.8x)
  and the Lost Miners stayed pale from their glow, so a second pass darkened bone and beards again.
- All 7 pass check_models; 3D page version 5. Still waiting for the OK before the game install.

**Done (owner: "we're good to go on these guys").** All 7 models were put into the game (the old painted pictures were deleted and Godot made new ones). check_models passed on all 7. Tests passed: test_skeleton_miners (12/12) and test_model_rules (9/9). The minercheck robot showed the dark miners in a dungeon. F527 is crossed off.
- Hurdle: the owner's new journal rule arrived after I had already written into JOURNAL.md. I moved my lines into this inbox file, so the other chats' JOURNAL lines stayed untouched.
