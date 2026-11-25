## Nov 26: the bronze dungeon recipes had to be saved twice (F844 step 5)

**What happened**
- A later commit from another chat (f24bb51b, "F873 confirmed...") put back the old copper versions of my files
  (the dungeon list, the scrolls in items.gd and 7 tests). It was built from copies taken before my commit. This is the
  same race I hit earlier in this chat. My changes were still on disk, so I committed them again (e78c0696).
- The Quiet Barrows (the 6th built dungeon) arrived meanwhile; its scroll now teaches the Bronze Spear, and the
  "every built dungeon teaches bronze" test counts 6 dungeons. test_dungeon_list and test_barrows pass.
- Full suite (saved run): 44 failed checks. Nearly all came from main.gd failing to load partway through the run,
  because the Barrows chat's main.gd landed before its cave_maker.gd. All scripts load again now
  (test_scripts_load passes). None of the failures were about recipes or dungeon loot.

**Lesson**
- A commit built from a private index must take its file copies and commit in one quick step. Afterwards, check that
  the commit changed only your own files (`git show --stat`), because another chat's work can be lost by accident.
