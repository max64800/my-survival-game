# Nov 22: Rebuilding Chest fixes — it rebuilds by itself now (F631, F633-F636)

**What we did**
- Owner played the tower rebuild again and found six problems. Fixed five of them, one at a time, each with its own test:
  - **F631** — putting wood or stone into a Rebuilding Chest used to do nothing until someone stood next to it holding the Build Hammer and swung. Now putting the materials in is enough: the rebuild starts and finishes by itself, with nobody there. In `src/build/builder.gd`, the per-site update loop (`_tick_sites`) had one check: "is someone standing here with a hammer?" — if not, it posted "Paused" and skipped the site. That check is now skipped for ruins only; normal Builder's Chest sites still need the hammer, same as before.
  - **F567 (repeat)** — this one goes with F631: the blue "ghost plan" outline that shows what's about to be built was still turning on for ruins sometimes. Since a ruin now rebuilds unattended, the blue plan is switched off for ruins completely, for good — it's only useful when a person is actively placing pieces with the hammer.
  - **F633** — the mouse cursor sometimes stayed hidden after opening the rebuild menu. Any chest/box menu now explicitly shows the cursor the moment it opens, instead of assuming it already was showing.
  - **F634** — the stone/clay-brick card used to show in the menu even with zero stone or bricks in your bag. Now it only appears once you're actually carrying that ruin's hard material; the wood card always shows (wood is always an option).
  - **F635** — the whole menu was too small, and the only way to learn what "rootwood" or "rope" meant was to hover over the picture. Made the pictures and slots bigger, and now the item's name is printed under every picture all the time.
  - **F636** — after the tower finished rebuilding, nothing told you it was done. Added a line that pops up on everyone's screen the moment it finishes ("The old tower stands again!"), right before the existing "Blueprint learned" card, which already says "V opens your blueprints".
- **F637** (ruin blueprints shouldn't be findable as loose pages) was already being fixed by another Claude working in this same folder at the same time — their file wasn't touched.

**Mistakes and hurdles**
- The game's "ghost" (blue plan) visibility got set in three different spots in `builder.gd` (when a site is created, when plans are shown/hidden, and per-tick), so the F567 fix needed all three places checked, not just one — missing one of them would have let the blue plan sneak back on in some situation.
- A chest's "is this a ruin?" flag (`site.has("ruin")`) only gets added to the site's data a little while after the site itself is first created, so the very first check inside the function that creates a site had to ask the chest directly ("is your kind 'rebuild'?") instead of relying on that flag, which doesn't exist yet at that exact moment.
- Rewrote the test for F631 instead of just adding checks, since "wait for a hammer-holding player standing nearby" was baked into the old test's setup — the new test instead checks the opposite: nobody stands there, nobody swings, and it still finishes.
- Checked for regressions by re-running every other ruin test file (tower, brewhall, manor, outpost, spire, builder). One run of the brewhall test failed once with an unrelated engine texture-loading error; it passed cleanly on a second run, so it was a one-off hiccup, not something this fix broke.

**Files changed**
- `src/build/builder.gd` — ruin sites skip the hammer/stand-by-it check; blue plan permanently off for ruins; new broadcast line fired when a ruin finishes.
- `src/ui/box_panel.gd` — cursor shown on open; stone/brick card hidden until you have the material; bigger slots/pictures; item names always shown.
- `src/net/game_authority.gd` — new `_ev_ruin_rebuilt` line, sent to every player.
- `tests/test_tower_rebuild_play.gd` — rewritten test covers all five fixes together, plus the existing lag/junk-cleanup checks.
- `FEEDBACK.md`, `FEEDBACK-done.md` — F631, F567, F633, F634, F635, F636 crossed off and moved to done; F637 left open (another Claude's in-progress work).
