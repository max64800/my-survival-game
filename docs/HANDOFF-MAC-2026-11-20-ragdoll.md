# Handoff from the Mac: rag doll on big hits (November 20, 2026, F237)

Read this on the PC after `git pull --ff-only`. Commit `3803207`. Background: `docs/design/zone1-dungeons/traps-and-variety.md`
(which traps cause a ragdoll: triple cart tunnel, swinging boulder / forge anvil, spiked flail).

## What the owner asked for
- A mine cart, a swinging boulder or anvil, or a spiked flail hits a player: the dwarf goes floppy like a rag doll,
  tumbles, then gets back up after a moment.
- Every co-op player sees the same tumble (friends will record it).
- A simple "big hit" entry point the PC's trap code can call. The Mac wrote **no trap code** and did not touch
  Mossgate Hold (`cave_maker.gd`, `dungeon_map.gd`).

## The one call your trap code needs
```gdscript
dwarf.big_hit(push: Vector3)   # push = direction × speed in m/s, e.g. cart_dir * 8.0
```
- Call it **on the host only** (where traps run). Calls on a client are ignored.
- It does **no damage**. The trap deals its own damage (the doc: cart = big hit, 2 hits = dead; flail = hurts).
- Up-pop is added inside (35% of the push's strength), so pass a sideways push.
- Hit again while floppy: the new push adds on and the 2.2 s clock starts over.
- With the old non-rig looks (`DwarfModel.art != "dwarf"`) it falls back to `knock_down()`.
- Tested strength: 8 m/s throws him about 7 m on a flat floor. That's a lot; 5-6 m/s is probably plenty for carts.

## Files
| File | What |
|---|---|
| `src/player/dwarf_ragdoll.gd` | `DwarfRagdoll` (a `SkeletonModifier3D`): the rag doll itself |
| `src/player/dwarf.gd` | `big_hit()`, the `_net_big_hit` RPC, `var ragdoll`, two early returns while floppy |
| `tests/test_ragdoll.gd` | test room check: thrown the right way, tumbles, stays above the floor, can't walk, gets up, walks again |
| `src/debug/ragdoll_room.gd` | visible test room: 4 throws, pictures, quits by itself |

Test room: `godot --audio-driver Dummy --path . --script res://src/debug/ragdoll_room.gd -- claude=ragdoll shots=<folder>`
Test: `tools\run_tests.bat only=test_ragdoll` (passes on the Mac).

## How it works
- **Not Godot's PhysicalBone3D / PhysicalBoneSimulator3D, on purpose.** `DwarfProportions` scales and moves the bones
  every frame (and the Skeleton3D node itself is non-uniformly scaled, ~1.19/0.99/1.19). Physical bones under a
  scaled skeleton misbehave, and rigid bodies carry no scale, so the dwarf would lose his shape.
- Instead: 10 `RigidBody3D` pieces in world space (a `top_level` node): pelvis, chest+head (capsule + head sphere),
  upper/lower arms, thighs, calves. They're joined by `ConeTwistJoint3D` (swing 70°, twist 35°), collide with
  `TERRAIN_LAYER | PIECE_LAYER` only, and don't collide with each other.
- Each frame the modifier sets the matching bones' **rotations** to follow their pieces. It runs **before
  DwarfProportions** (moved to the first modifier slot when it's created), so the dwarf shaping still applies on top.
- The skeleton's root bone position is set so the final (shaped) pelvis lands exactly on the hips piece. This uses
  `DwarfProportions._drop`, because the shaper lowers the hips after us. The pelvis and root pose are held at their hit-time values,
  because the "knock" animation would drag them.
- The Dwarf node itself (camera, `_net_pose`, getting up) stays **on the floor under the hips** (one ray per frame).
- Timeline: 2.2 s floppy → pieces freeze, "wake" (get-up) animation starts, modifier `influence` fades 1 → 0 over
  0.5 s → pieces deleted, `fight.stagger = 0.6` while the get-up finishes.
- The unsteered bones (neck, hands, feet, fingers) play the "knock" animation meanwhile.

## Co-op
- `big_hit` → `_net_big_hit.rpc(push)` (`any_peer`, `call_local`, `reliable`). The receiver rejects any sender id > 1,
  so only the host can throw dwarfs. Everyone starts the same tumble at the same time with the same push.
- Physics isn't identical across machines, so on a **friend's** copy of a dwarf the hips piece is nudged sideways each
  frame toward the owner's position (`_net_pos` + hit offset, `PULL = 4`). Limbs flop locally, but he lands in the
  same spot for everyone. After getting up, the normal `_net_pos` lerp takes over again.
- While floppy, `Dwarf._physics_process` returns early (no walking, fighting or digging), and a friend's dwarf skips
  its `_net_pos` lerp in `_process`.
- **Not tested with two real players.** Please run netcheck (or two machines) with a forced `big_hit` before the
  owner records it.

## Gotcha found on the way (worth remembering)
`Skeleton3D.get_bone_global_pose()` read **outside** the skeleton's update returns the plain animation pose
(human-sized), not the result after the modifiers. For the final dwarf-shaped pose, read it in the
`skeleton_updated` signal or inside a modifier. `start()` therefore `await`s `skeleton_updated` once before building the
pieces.

## Not done / ideas for later
- The trap hookups themselves (carts, boulder/anvil, flail) and their damage.
- The tumble has no sound or camera shake. `add_shake()` and the Sfx are there if the owner wants them.
- Being hit while floppy doesn't hurt more. The trap decides that.
- The rag doll pieces ignore monsters and other players (only rock and built pieces).
- No godot-prompter skills were installed on the Mac, so none was checked. If the PC has a ragdoll/physics-bones
  skill, compare against it.

## Test suite state on the Mac (Nov 20)
Full run: 506 checks, 14 failed, all outside this work: test_authority (4), test_build_menu (doesn't compile),
test_cave_floor crystals, test_dwarf braids + aim (these 2 fail without the rag doll too), test_monsters (2),
test_progression kill counts, test_ruin_tower (2), test_visuals tool models. Other chats were editing build files at
the same time.
