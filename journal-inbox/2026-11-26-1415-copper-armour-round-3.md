## 2026-11-26: Copper armour, round 3 (F914)

**What we did**
- The owner said round 2 was "a little bit better" but asked for five things: one long eye slit, a lower helmet,
  better pants, no open elbows or hands, and a walking animation. Then the owner sent the concept picture again:
  "make sure that you can see each plate, the bolts, the rims around each plate".
- I studied the picture and listed what it shows. Every plate has a bright raised rim, hammered dents and rivets at the
  corners. The pauldrons are layered bands. The breastplate points down in the middle. The legs have thigh plates,
  a six-sided knee cap and shin plates.
- `tools/asset_forge/builds/dwarf_armor.py`:
  - `hard_rim()`: a rolled rim on every hard plate. `hard_tint()` paints the rim polished and adds a dark shadow line just inside it.
  - `hammer_dents()`: dents in the shape and in the paint.
  - Helmet: one eye slit across both eyes, the face guard down to the moustache, cheek guards 3 cm lower, more rivets.
  - Chest: the breastplate and belly band now dip into a V (`chest_v`). The rivet rows follow the V.
  - Arms: a new set of arm plates (upper arm, elbow plate with a round elbow cap, forearm plate) joined to the
    gauntlet cuff, so no skin shows at the elbow.
  - New `build_legs()`: thigh plates, a knee band, a six-sided knee cap and shin plates. The Copper Greaves now wear them.
- 3D page (Version 5): a "▶ Walk" button. Both dwarfs walk on the spot, and the armour moves with the body bones.
  A new "Legs close" view.

**Mistakes and hurdles**
- **Blender crashed (out of memory)** on the first full build. The smoothing step (subsurf) on the 202,000-face chest
  leather used up all the memory. Fix: smooth only meshes under 150,000 faces (it was 260,000).
- **A lumpy "X" crease on the shoulder guard.** The pauldron followed every lump of the body, and the new rim made the
  lumps easy to see. Fix: blur the surface it follows more (`blur(soft, 5)`).
- **The quick review pictures look flat and brown.** They have no paint or shine, so the shine can't be judged there.
  I judged the look on the 3D page instead, by screenshotting it myself.
- Rims came back: in round 1, the soft rims looked like leather, so round 2 removed them. The picture clearly has rims,
  so round 3 brings them back as thin, hard metal edges with a shadow line.
- The dwarf test run had 5 failures: stun meter, camera near rocks, braids, aiming, fist swings. Other chats have
  unsaved changes in those game files. The armour fit test passed.

**Left to do:** the owner's play test (Copper Helm, Mail, Greaves, Boots).
