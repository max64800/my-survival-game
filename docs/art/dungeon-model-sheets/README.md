# Dungeon model sheets (Zone 1, F237)

*Nov 20, 2026 (Mac). One sheet per new dungeon model, for the PC Claude to build in Blender.*
Source list: `docs/design/zone1-dungeons/traps-and-variety.md` → "Assets to make". Rules: `docs/art/MODEL-RULES.md`.

## How to use a sheet
- The **picture is concept art for the look only** (owner, Nov 20). The written sheet wins on sizes, parts and moves.
- **Sizes are whole 2 m grid squares** (1 or 2 squares, never 1.5). The owner spotted the brick portcullis picture
  reading as 1.5 squares wide: build what the sheet says.
- **Doors and doorways reuse the existing round door** (r 0.78 m, centre 0.70 m, Rule 5). Never redraw it.
- Axes like the existing build scripts: x across, y up, z = front (+z faces the room), origin bottom-centre.
- Part names in the tables are the names the game code will look for (like `frame` / `weight` on `trap_crusher`).
- Owner's trap rules: medieval only (no fire jets, no pistons), molten metal stays inside stone channels,
  every trap has a clue and a safe way through.
- Before calling a model done: run `tools/model_check/check_models.py` on it, and make a side-by-side with its picture.

## The sheets
| Sheet | Material | Dungeons |
|---|---|---|
| **Traps** | | |
| [Swinging boulder](trap_swing_boulder.md) | wood | Lampwick, ⭐ Mossprop, Barrows |
| [Swinging anvil](trap_swing_anvil.md) | forge | Emberdeep, Hammerfall |
| [Rolling boulder + ramp + alcove](trap_roll_boulder.md) | stone | ⭐ Barrows |
| [Rolling anvil](trap_roll_anvil.md) | forge | ⭐ Emberdeep |
| [Triple rail tunnel set](rail_triple.md) | wood | ⭐ Lampwick, Hammerfall |
| [Forge ore cart](ore_cart.md) | forge | Hammerfall |
| [Push wall](trap_push_wall.md) | wood, stone, brick | ⭐ Pell's, Brassgate, Emberdeep, Hammerfall, Cinderhold |
| [Tipping brazier + embers](trap_brazier_tip.md) | forge | Emberdeep, Hammerfall, Cinderhold |
| [Pendulum blade](trap_pendulum_blade.md) | stone | ⭐ Brassgate, Hammerfall |
| [Bell pendulum](trap_bell_pendulum.md) | stone | ⭐ Vigil |
| [Spear wall](trap_spear_wall.md) | wood, stone, brick | Pell's, Mossprop, Barrows, Shieldbearers, Vigil |
| [Tripwire crossbow](trap_tripwire_crossbow.md) | wood, stone | 6 dungeons |
| [Bear jaws](trap_bear_jaws.md) | iron | 6 dungeons |
| [Collapsing double stairs](stairs_collapsing.md) | stone, brick | ⭐ Tomb, Cinderhold |
| [Spiked flail](trap_flail.md) | wood + iron | ⭐ Shieldbearers, Hammerfall, Cinderhold |
| [Trapped chest spike plate](trap_chest_spikes.md) | wood, stone, brick | most dungeons |
| [Falling ceiling stones](trap_ceiling_stones.md) | stone | Tomb, Barrows, Vigil |
| [Stone crusher](trap_crusher_stone.md) | stone, brick | #5-#9 |
| [Great crusher](trap_crusher_great.md) | stone + brass | Vigil |
| [Great press](trap_press.md) | forge | ⭐ Hammerfall |
| [Stone/brick bridge slabs + cracked](bridge_stone_slab.md) | stone, brick | ⭐ Tomb, Barrows, Shieldbearers, Vigil, Cinderhold |
| [Chain bridge section](bridge_chain_section.md) | wood + iron | ⭐ Cinderhold |
| [Swinging crucible](trap_crucible_swing.md) | forge | Emberdeep, Cinderhold |
| [Molten channel](molten_channel.md) | forge | Emberdeep, Hammerfall, Cinderhold |
| [Casting mould + lids](mould_lid.md) | forge | ⭐ Cinderhold |
| **Doors, ways out** | | |
| [Dropping portcullis](portcullis.md) | stone, brick | Tomb, Brassgate, Shieldbearers, Hammerfall, Cinderhold |
| [Locked round door + 9 keys](door_locked_round.md) | stone, brick | #5-#12 |
| [Dungeon entrance](dungeon_entrance.md) | stone, brick | #5-#12 |
| [Rope lift + winch](lift_platform.md) | wood | Pell's, Emberdeep |
| [Rope slide](rope_slide.md) | wood | Mossprop |

⭐ = that dungeon's signature trap.

## Not covered here
- Stone/brick versions of `wall_cracked`, `floor_loose_stone`, `floor_old` ("maybe" in the list: only if the root
  wood ones don't fit stone).
- The healing shrine (check the PC's kit first).
- Creatures (7 KayKit dwarf versions + 9 mini bosses): see `docs/design/zone1-dungeons/00-missing-and-build-order.md`.
- **No picture (ChatGPT refused, Nov 20):** tripwire crossbow, spiked flail, stone crusher, great crusher, great
  press. Their sheets say which existing model or picture to copy the look from. Not reworded to get round the refusal.
- Pictures: made in ChatGPT (chat "Describe dungeon trap props"), shrunk to 1024 px JPG. Logged in `CREDITS.md`.
