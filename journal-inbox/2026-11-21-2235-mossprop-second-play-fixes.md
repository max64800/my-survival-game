## Nov 21: Mossprop Workings, fixes from the owner's second play (F582-F593)

The owner played dungeon 4 a second time and wrote down 12 things. All 12 are fixed, each with a test.

**What we did.**
- **Rock lumps out (F582, came back).** The big grey lumps and moss shelves on the cave walls are gone. The owner
  said "whole game", so the grove rocks and wall shelves (already switched off in the open caves) were deleted too,
  with their 50 model files and the shelf build script.
- **A cave, not a box (F583, came back).** Instead of sticking things on flat walls, the cave's own west, east and
  south walls and its roof now bulge in and dimple out (up to 1.8 m). The floor and the tower's cliff stay flat, and
  the rock stays clear of everything built.
- **Stalactites (F584).** About 100 became 32 that just hang, plus 12 loose ones that crack and really fall when
  you walk near. Each loose one hangs from a flat bit of roof, at least 4 m from the next, with 5 m to fall.
- **Trapped chest (F585, came back).** The cause: a crossbow bolt flew straight through chests (they weren't on the
  bolt's list of things it can hit). Now the bolt stops, the spikes slam up empty, and the lid springs open.
- **Statue hits (F586).** Pickaxe hits to break a dead creature's statue: bats 1, others 2, bosses 5.
- **Dart wall (F587).** The cause: Mossprop used a show-only dart wall model, and nothing could set it off. Now it's
  the working one from Old Pell's and Lampwick, with a tripwire across the Prop Room.
- **Vault wall gaps (F588, came back).** The cracked wall is 2 m wide but sat in a 4 m hole. A narrow wall now
  fills each side.
- **Top deck (F589).** 9 more rotten boards; one safe way stays, from the upper ladder to the Crusher Gallery.
- **Crushers (F590, came back).** The cause: they waited for a "Pack Hall" room Mossprop doesn't have. Now they always run.
- **Boss room door (F591, came back).** Both ways into the boss room got a round door, and a new test checks that
  every dungeon's boss room has doors on all its ways in (Lampwick's back exit is allowed on purpose).
- **No reviving (F592).** The Prop Warden doesn't raise fallen miners in Mossprop. The code stays for the next boss.
- **Lost Miners (F593, came back).** Picks reach 1.5/1.4 m (were 1.8/1.9) and their leap is slower than walking. The
  test counts a real player's reaction time (0.3 s): walk straight off after the spark and every hit misses.

**Mistakes and hurdles (Claude's own).**
- The first stalactite placement put one half inside a roof dimple. Fixed by only hanging loose ones where the roof
  is flat under them.
- The falling stalactites failed the "rock stays out of built things" test, because they hang over the walkways on
  purpose. They are checked by the hanging test instead.
- Used a wrong name in a test (`ps.hp`; health lives in `ps.vitals.health`), and GDScript couldn't guess one
  variable's type. Both fixed.
- The boss-door test first failed on Lampwick's back exit, which is meant to stay open. Allowed it by name.
- Lost Miners: the first numbers still let the quick Pick Jab land (the gap came out exactly equal), so it got 0.2 m shorter.
- The first no-reviving test passed for the wrong reason (3 miners were already standing, which also blocks
  reviving). It got its own clean test. That test then crashed after it finished, because the boss had a pretend
  dungeon with no rooms. It's reset before the test ends now.
- Ran `git stash` / `git stash pop` once without need while other chats had unsaved work. It came back cleanly,
  but it was risky; don't do that in a shared folder.
- Deleting the rock models: some of their picture files weren't in git, so `git rm` refused; removed those by hand.
