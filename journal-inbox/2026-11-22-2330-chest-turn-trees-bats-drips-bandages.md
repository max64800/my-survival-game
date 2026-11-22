## Nov 22: chest turning, tree chips, craft sounds, calmer bats, dripstone drops, slow-healing bandages

**What we did (7 owner notes, one at a time, each with a test):**
- **F632 (the big note): a turned chest went down facing the wrong way.** The real chest (and every station) turns its
  model around (models are built facing the other way), but the see-through preview didn't. So the preview showed
  the chest's back as its front, and you turned it "wrong" on purpose. Now the preview uses the same model and the
  same turn. Small helpers `Storage.model_id` and `Station.model_id` make sure both pick the same model.
- **F627 + F628: a breaking Root Tree threw a giant "log" and left dark shards floating.** There is no log model: the
  "log" was the three ~1 m bark chunks each chip burst throws. The chips started *inside* the trunk's solid shape,
  so some got stuck in the air. Now the chips are a third of the size and start just outside the bark (a ray finds it).
- **F629: crafting 10 ropes played 10 identical sounds at once.** Now one sound, plus at most two quieter ones
  spread out, each a little higher or lower.
- **F630: "bees" flew too fast with sharp turns.** The "bees" are the little moths that circle the crystals. They darted
  at up to 4 m/s inside a small circle and snapped round to face a new way in one frame. Now they drift at 0.35-0.75 m/s,
  bend their flight gently and swing round at most ~140° a second.
- **F654 (new): dripstone drops vanished halfway down.** Each drop lived 1.6 s, so on a high ceiling it disappeared in
  mid-air. Now every dripstone measures how far down its floor is; its drops live exactly long enough to land, and a
  small splash shows where the Drip Bucket goes.
- **F655 (new): bandages.** The owner chose 5 tree moss + 10 cave fiber (no rope), healing 5 a second for 5 s instead
  of 25 at once. Trying it in a dungeon, the owner found 5 s still way too fast: now 25 over 15 s. The 30 s wait
  stays; the screen shows "Bandage healing N s".

**Mistakes and hurdles:**
- **Wrong creature.** The note said bats ("bees") and I took "bees" as the owner's nickname for the Cave Bats, so I
  calmed the bats. The owner meant the moths. Worse, another Claude's commits had already swept my unsaved bat changes
  into their own commits. I undid just my bat lines (old speeds and turning back) and fixed the moths instead. Lesson:
  when a note names a creature the game doesn't have, ask which one is meant before changing anything.
- The first moth test failed (13° turn in a 20th of a second): a soft blend still turns fast when the new way is far
  off. Fixed with a hard cap on turning speed.
- The test runner couldn't find Godot (not on the PATH). Fixed by setting the GODOT path first.
- An edit failed because I used two tabs where the file had one.
- A file listing printed far too much; I switched to narrow searches.
- I tried to take a screenshot of a breaking tree, but a stone bridge blocked the view. I dropped the picture and
  trusted the test instead (and removed the temporary preview mode again).
- A spider poison test failed. I checked it on a clean copy of the last commit: it fails there too, so it was already
  broken before my changes (not touched here).
- My first drip test failed on 3 of 173 drips: they hang over pits deeper than 40 m. The floor search now looks 80 m
  down, and a drip over a truly bottomless pit just lets its drops fall 30 m.
- I first wrote F643/F644 for the two new notes, but another Claude had already taken F642/F643 meanwhile. I found the
  real next free numbers (F654/F655) and renamed them.
