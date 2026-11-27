## 2026-11-27: Copper armour round 7, the hand-built plates copy the picture-made shapes (F914)

**What we did:**
- The owner liked the picture-made copper set more, but wanted the hammered copper of round 6 on it: "everything,
  shape, color, details, just texture needs to be adjusted". The picture-made mesh can't ship (its maker's licence
  bans some countries), so Claude measured it by script and rebuilt the shapes by hand in
  `tools/asset_forge/builds/copper_plate_armor.py`. The picture mesh was only a size guide.
- Helmet: much bigger bell (36% wider, 7.5 cm taller) with a neck guard that hangs lower at the back, a thick
  riveted brow band, a ridge strip over the top with seven big rivets, and dark eye slits.
- Chest: a wider, taller breastplate that bulges out a little, a thicker belt, bigger domed shoulder caps with six
  rivets, and the collar moved up to the neck.
- Shiny trims were made redder (they looked silver in the game).
- The comparison page now shows the picture-made set next to the round 7 copy.

**Tests:** the full suite had a few failures (braid, aim, stun, fist). All four were failing before this work (see
earlier journal entries), and the camera test wears no armour, so none come from the armour. The armour fit test
`test_hand_built_armor_fits_the_body` passes.

**Mistakes and hurdles:**
- Claude tried running the tests in a separate copy of the folder (a "worktree"). The owner stopped it, and
  deleting the copy failed with "Filename too long". It was removed with a long-path delete and `git worktree prune`.
- The front of the ridge strip stuck out like a visor, because there is no helmet under it at the eye holes. It was
  made shorter at the front.
- The bottom rim stuck out at the back. It was raised and made thinner.
- The ridge rivets were placed on the helmet shell, so they ended up hidden 7 mm under the strip. A measuring
  script found it, and now they sit on the finished strip.
- The first brow rivet spacing gave far too many rivets (the number was a count of rivets per angle, not a
  distance). Fixed to about 13.
- A grey "fan" showed at the shoulders: the dark leather undercoat peeking out. The breastplate was widened and
  raised and the shoulder caps made bigger. Tiny grey corners remain in the armpits.
- The eye holes showed bright skin. They are now dark slits instead of holes.
- Godot pulled the plate textures out of the .glb into their own files, and round 6 forgot to commit them. They are
  committed now.
