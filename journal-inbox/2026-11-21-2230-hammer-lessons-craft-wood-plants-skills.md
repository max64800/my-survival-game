## Nov 21: Build Hammer lessons, craft a whole amount, wood and plant fixes, skills window (Claude 2)

The owner's play notes from the tower-rebuild play, one small batch at a time:
- **Build Hammer lessons (F579).** The hammer now teaches 5 steps one by one (choose a piece, place, turn, lift,
  pick up). Each one ticks off when you do it, then only a one-line key list is left. Progress is kept in its own
  file (`user://build_lessons.cfg`), not in the world save; test runs use a separate file.
- **Craft an amount in one go (F555, 3rd try).** Asking for 10 now runs one bar for all 10 (a bit longer than one,
  at most 8 s) and makes them all at the end. Before, it made them one at a time in a chain.
- **Wood and plants.** A pickaxe on wood is twice as fast as before (5 hits on a root, an axe still 2) (F550). Wood
  no longer sounds like metal (F558). The cause: the game didn't tell the dwarf that a hit was on wood, so the first
  hit played the rock-digging sound, and a used-up tree played a metal "clink". Glowing vines can be picked with E
  (F569). Fiber: 4-6 per tuft, 3 per fern, 2 per vine (F575). A small root every ~14 m along every tunnel
  (353 → 862 roots, kept out of treasure zones and paths) (F566). The fiber tufts are now soft, flat, bending blades,
  not sharp spikes (F553). No more "grows back in 45 min" message (F552).
- **Skills window (F576).** It opens on Perks. The Skills tab shows each skill's name, level bar and its 4 ★ lines
  (one line each); "each level gives..." moved to the hover text.
- **Copper gear from ruins (F554).** On Nov 19 the owner chose "every copper piece needs its own page", so Claude
  asked first. The owner's answer: copper tools from ruins, armour and weapons from dungeons. Ruin chests now give
  only Cook's and Toolmaker's Pages; the 12 dungeons already teach every copper weapon and armour piece.

**Mistakes and hurdles (Claude's own).**
- Two text replacements failed because Claude got the tab count of the old line wrong. Redone by reading the exact lines first.
- The lessons test failed at first: the "is this a Claude test?" check doesn't see the test runner. Added a check
  for the test runner itself.
- A commit failed ("cannot lock HEAD") because another Claude committed at the same moment. Simply committed again.
- The first tunnel-roots version added a root on every tiny tunnel piece (1527 roots, far too many). Changed it to
  one root per 14 m walked.
- Copying the test setup into the new test file cut the last function in half (a parse error). Fixed.
- An older test said "a pickaxe takes at least 4× longer than an axe", which the F550 change broke. Updated to 2×.
- Started changing copper gear to unlock with copper ingots for F554, then saw the owner's Nov 19 rule in the code
  comment and undid it, then asked the owner.
- Skills tab: 3 cards a row was too tall and 4 a row was a bit too wide. Fixed with 4 a row, slightly smaller star
  text and two shorter star texts. A test now measures that it all fits.
- The screenshot tool's `tab=` change didn't save the first time (the script's text match failed without saying
  so). Claude looked at a picture of the old window before noticing.
- An older page test expected ruins to roll all 4 page kinds; updated to food and tools.
- The full test run's output was cut to its last 40 lines, so most failures were hidden. Re-ran the nearby tests
  instead. Failures not from this work: test_only_the_five_creatures_are_left (fails without these changes too),
  test_no_raising_in_mossprop, the sword-swing speed, the braid and fist tests; test_aim_skips_things_behind_the_dwarf
  passes on its own.
