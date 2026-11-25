## 2026-11-25: The Honour Chapel's portcullis ambush (F843, Tomb of Hald Ironbrow)

**What we did**
- New model `assets/models/dungeon/portcullis.glb`, built by `tools/asset_forge/builds/dungeon_portcullis.py`: the
  Stonehold round doorway itself ("frame") plus a rusted iron grille cut to the round hole ("gate"): an iron rim, 9
  square bars with spike teeth, straps riveted on both faces. Because the model *is* the doorway, it replaces the plain
  doorway at that junction, so there are never two stone frames in one spot (no shimmer). One render round was enough.
- `src/world/dungeon_build.gd`: a new "portcullis" kind. The host drops it when a living dwarf is 2.5 m into the
  Honour Chapel while the room's creatures live (MonsterManager.dungeon_room), and lifts it when they all die or when
  no living dwarf is left in the room. State in `world_state.dungeon_shut` + an rpc, like the hand doors, so friends
  who join see it the same. It slams down in 0.25 s with a heavy hit sound and grinds up in 2.5 s. Only the gate's own
  collision box comes and goes. It is unbreakable (added to both "can't hit this" lists).
- `tools/dungeons/make_hald.py`: the broken_stair -> honour_chapel doorway gets the portcullis; plan regenerated.
- Two new tests in `tests/test_hald.gd`: the ambush (raised at the start, half a step in = nothing, deeper = it
  slams, he dies = it lifts, everyone leaves = it lifts) and "every open stone doorway lets you through".

**Mistakes and hurdles**
- **Every Hald doorway was a solid wall (found while testing).** Models without their own collision boxes get one big
  box round the whole model. The Stonehold doorway (`build/doorway__cut_stone.glb`) had none, so each of Hald's
  doorways was blocked, hole and all. Hald is the first stone dungeon, so nobody had walked one yet. Fixed: it now gets
  side and top boxes like the plank doorway, and the new test walks every one.
- The "is it blocked" test first flagged the way-out gate, the round door and the Bronze door: those are *meant* to be
  shut. The test now skips doorways that have a real door in them.
- A "material is null" engine error appeared in my new test. It came from the Shield-Brother test before it, which frees
  its whole World at the end of the frame, and the error landed in whatever test ran next. Moving my tests above it
  (keeping that test last, with a note) fixed it. Making it free right away only moved the error into that test.
- A long Python edit sent through a bash heredoc broke on quoting (the RTK hook rewrites commands). Writing the script
  to a scratch file and running it worked.
- Another chat had uncommitted lines in `dungeon_build.gd` and `CREDITS.md` (footstep dust, tin ore), so only my own
  lines were committed, through a scratch git index.

**Also this session**
- The owner asked for food and level 15 every time Dev Dungeon starts: `src/debug/dungeon_test_start.gd` now gives 10 each
  of stew, miner's pie, beetle roast, moss ale and bellcap juice, and raises the dwarf to level 15 (with the 15 perk points).
  The owner's next screenshot still showed level 2: that run had started before the change, so a restart is needed.
- The owner's Tomb of Hald play test was logged as F846-F859, plus F860 🔁 (dungeons too bright, back for the 3rd time,
  so it went into "Things that keep coming back" with a different plan: dimmer and fewer lights, not more junk).
- Hurdle: main had moved on GitHub, and other chats had unsaved changes in CREDITS.md and main.gd, so pulling first
  would have mixed their work in. My commit went in through a scratch git index; the pull waits for a clean moment.
