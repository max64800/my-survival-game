class_name DungeonBuild
extends Node3D
## Builds a dungeon's insides in the game (owner, Nov 19): the root wood floors, walls, ceilings and doorways, the
## traps, doors, furniture and torches, from the dungeon's plan (blueprints/dungeons/<map>.json, made by
## tools/dungeons/make_mossgate.py; the 3D page "Mossgate Hold 3D" shows the same file).
## Every computer builds the same thing from the world number (the Cave Maker's dungeon spot + the plan). Repeated
## models are drawn in batches (MultiMesh), so 1,700 pieces cost about as much as 60. The walls can't be broken.
##
## Things you CAN break (owner's first play, Nov 19) are built one by one, each with its own body: furniture and crates
## (smash them: a little root wood + small finds), the rubble wall, the hidden boulder (exactly like a cave boulder),
## the stalactites (they fall when you walk under them, or when a bolt hits them) and the cracked floor tiles over the
## spike pit (they give way under you). Co-op: you ask -> the host decides (hits, falls) -> everyone sees it. The host
## keeps what's broken in world_state.dungeon_broken (saved, and sent to friends who join).
## Falling into the chasm or the spike pit kills you (decisions: instant death; the grave goes where you last stood).

const PLANS := {"mossgate": "res://blueprints/dungeons/mossgate_hold.json", "lampwick": "res://blueprints/dungeons/lampwick_drift.json",
	"pell": "res://blueprints/dungeons/old_pells_diggings.json", "mossprop": "res://blueprints/dungeons/mossprop_workings.json",
	"hald": "res://blueprints/dungeons/tomb_of_hald_ironbrow.json", "barrows": "res://blueprints/dungeons/the_quiet_barrows.json",
	"brassgate": "res://blueprints/dungeons/brassgate_vault.json"}
## What you bump into, in each model's own metres: [centre, size] boxes. Models not listed and not in NO_BODY get
## the box round the whole model.
const BOXES := {
	"build/floor__plank_root.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/floor_old.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/floor_loose_stone.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/floor_loose_flagstone.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],  # (Hald's stone twin, F856)
	"dungeon/trap_floor_break.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"build/wall__plank_root.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/wall_old.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/trap_dart_wall.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/wall_cracked.glb": [[Vector3(0, 1, 0.05), Vector3(2, 2, 0.35)]],
	# The Tomb of Hald's stone and iron twins (owner, Nov 25: a dark STONE dungeon; builds/dungeon_stonehold.py).
	"dungeon/wall_cracked_stone.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.3)]],
	"dungeon/gate_iron.glb": [[Vector3(0, 0.75, 0.05), Vector3(1.5, 1.5, 0.14)]],
	"dungeon/lever_iron.glb": [[Vector3(0, 1.05, 0.1), Vector3(0.4, 0.75, 0.22)]],
	"dungeon/trap_chest_spikes_stone.glb": [[Vector3(0, 0.125, 0), Vector3(2, 0.25, 4)]],
	"dungeon/entrance_stone.glb": [[Vector3(-1.22, 1.25, 0.02), Vector3(0.68, 2.5, 0.6)], [Vector3(1.22, 1.25, 0.02), Vector3(0.68, 2.5, 0.6)],
		[Vector3(0, 2.73, 0.02), Vector3(3.2, 0.5, 0.6)]],
	"build/wall_narrow__plank_root.glb": [[Vector3(0, 1, 0), Vector3(1, 2, 0.26)]],
	"build/half_wall__plank_root.glb": [[Vector3(0, 0.5, 0), Vector3(2, 1, 0.27)]],
	# The round doorway: its two sides and the top (the hole is about 1.3 m wide and 1.75 m high; the dungeon uses it
	# at 1.5x, and the boxes grow with it).
	"build/doorway__plank_root.glb": [[Vector3(-0.83, 1, 0), Vector3(0.34, 2, 0.25)], [Vector3(0.83, 1, 0), Vector3(0.34, 2, 0.25)],
		[Vector3(0, 1.88, 0), Vector3(1.4, 0.24, 0.25)]],
	"build/column__plank_root.glb": [[Vector3(0, 1, 0), Vector3(0.7, 2, 0.7)]],
	# The Stonehold round doorway (Hald's, F843): the same way through as the plank one (without these, the box round
	# the whole model shut every doorway). The portcullis is that doorway plus its gate; the gate's own box ("#gate",
	# from the floor to the top of the hole) is only there while it is down (DungeonBuild._move_portcullis).
	"build/doorway__cut_stone.glb": [[Vector3(-0.85, 1, 0), Vector3(0.3, 2, 0.3)], [Vector3(0.85, 1, 0), Vector3(0.3, 2, 0.3)],
		[Vector3(0, 1.75, 0), Vector3(1.4, 0.5, 0.3)]],
	"dungeon/portcullis.glb": [[Vector3(-0.85, 1, 0), Vector3(0.3, 2, 0.3)], [Vector3(0.85, 1, 0), Vector3(0.3, 2, 0.3)],
		[Vector3(0, 1.75, 0), Vector3(1.4, 0.5, 0.3)]],
	"dungeon/portcullis.glb#gate": [[Vector3(0, 0.83, 0), Vector3(1.5, 1.32, 0.12)]],
	# The bridge: just its deck, its top level with the floor boards (fall off the side and you fall). The posts: the two
	# posts and the deck between them (owner, Nov 19: one box round the whole frame blocked the way onto the bridge).
	# Owner, Nov 20: the hand ropes are solid too (you can't walk off through them), and the gap section has a 1 m hole in
	# its deck (its four middle planks are gone: you jump). The broken section's left hand rope is snapped: only the right.
	"dungeon/bridge_plank.glb": [[Vector3(0, 0.055, 0), Vector3(1.3, 0.11, 2.0)], [Vector3(-0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)],
		[Vector3(0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)]],
	"dungeon/bridge_plank_broken.glb": [[Vector3(0, 0.055, 0), Vector3(1.3, 0.11, 2.0)], [Vector3(0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)]],
	"dungeon/bridge_plank_gap.glb": [[Vector3(0, 0.055, -0.75), Vector3(1.3, 0.11, 0.5)], [Vector3(0, 0.055, 0.75), Vector3(1.3, 0.11, 0.5)],
		[Vector3(-0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)], [Vector3(0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)]],
	"dungeon/trap_crusher.glb": [[Vector3(0, 3.6, 0), Vector3(2.0, 0.28, 0.28)]],  # (its beam; the weight has its own moving box)
	# Owner, Nov 20 (3rd play): the posts' hand ropes (from the post to where the first section joins on) are solid too.
	"dungeon/bridge_posts.glb": [[Vector3(-0.64, 0.68, -0.05), Vector3(0.2, 1.2, 0.2)], [Vector3(0.64, 0.68, -0.05), Vector3(0.2, 1.2, 0.2)],
		[Vector3(0, 0.055, 0.6), Vector3(1.3, 0.11, 0.8)], [Vector3(-0.64, 0.55, 0.5), Vector3(0.08, 0.9, 1.0)],
		[Vector3(0.64, 0.55, 0.5), Vector3(0.08, 0.9, 1.0)]],
	# Just the ropes, no planks (owner, Nov 20, 3rd play: "too easy"): the hand ropes are solid, the rest is a 2 m jump.
	"dungeon/bridge_ropes.glb": [[Vector3(-0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)], [Vector3(0.64, 0.55, 0), Vector3(0.08, 0.9, 2.0)]],
	"dungeon/bridge_ropes_3m.glb": [[Vector3(-0.64, 0.55, 0), Vector3(0.08, 0.9, 3.0)], [Vector3(0.64, 0.55, 0), Vector3(0.08, 0.9, 3.0)]],
	"dungeon/lever.glb": [[Vector3(0, 1.05, 0.1), Vector3(0.4, 0.75, 0.22)]],  # (the board and the handle: E aims at it)
	"dungeon/door_loot.glb": [[Vector3(0, 0.75, 0), Vector3(1.5, 1.5, 0.16)]],
	"dungeon/gate_round.glb": [[Vector3(0, 0.75, 0.03), Vector3(1.5, 1.5, 0.15)]],
	# The round stone door's frame: its two stone sides and the top (you walk through its middle).
	"dungeon/dungeon_entrance.glb": [[Vector3(-1.2, 1.3, 0), Vector3(0.66, 2.6, 0.5)], [Vector3(1.2, 1.3, 0), Vector3(0.66, 2.6, 0.5)],
		[Vector3(0, 2.4, 0), Vector3(3.0, 0.6, 0.5)]],
	# Lampwick Drift (MineTraps): the rails' stone bed is the floor you walk on (and the carts roll on).
	"dungeon/rail_lane.glb": [[Vector3(0, 0.11, 0), Vector3(2, 0.22, 2)]],
	"dungeon/floor_grooved.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/trap_tripwire_wall.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/trap_tripwire_wall_stone.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/trap_crossbow_wall_stone.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],  # (Brassgate's guard slot)
	"dungeon/tripwire.glb": [[Vector3(0, 0.12, 0), Vector3(1, 0.08, 0.1)]],  # (stretched to the tunnel's width; hit it to cut it)
	"dungeon/tripwire_iron.glb": [[Vector3(0, 0.12, 0), Vector3(1, 0.08, 0.1)]],
	"dungeon/trap_bear_jaws.glb": [[Vector3(0, 0.02, 0), Vector3(0.8, 0.04, 0.5)]],  # (low: you walk onto it)
	# The swinging boulder's two posts, and its chain's top (shoot it there; the boulder itself is judged by distance).
	"dungeon/trap_swing_boulder.glb": [[Vector3(-1.74, 2, -0.08), Vector3(0.4, 4, 0.4)], [Vector3(1.74, 2, -0.08), Vector3(0.4, 4, 0.4)],
		[Vector3(0, 2.95, 0.13), Vector3(0.22, 1.0, 0.22)]],
	"dungeon/trap_chest_spikes.glb": [[Vector3(0, 0.125, 0), Vector3(2, 0.25, 4)]],
	"dungeon/mine_lamp.glb": [[Vector3(0, 0.2, 0.25), Vector3(0.3, 0.45, 0.45)]],  # (E aims at it)
	# Old Pell's working dart plate (thin: you walk onto it; a bolt can hit it). Mossgate's plates have no body.
	"dungeon/trap_dart_plate.glb": [[Vector3(0, 0.035, 0), Vector3(0.68, 0.07, 0.66)]],
	# Old Pell's spear walls and push walls are walls (the push wall's block has its own moving box); the lift's winch:
	# just its two posts (the shaft under its arms stays open). The lift platform has its own moving body.
	"dungeon/trap_spear_wall.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/recipe_stand.glb": [[Vector3(0, 0.48, 0), Vector3(0.7, 0.97, 0.62)]],
	"dungeon/recipe_stand_stone.glb": [[Vector3(0, 0.48, 0), Vector3(0.62, 0.97, 0.5)]],  # (Hald's, F856)
	"dungeon/trap_push_wall.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/trap_push_wall_stone.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],  # (Brassgate, F975)
	# Mossprop Workings: the old prop frame's two posts and cap (you walk between the posts); the rope slide's two posts
	# (top on the deck, bottom 10.24 m down and 18.9 m out in Base Camp; the rope itself has no body).
	"dungeon/prop_old.glb": [[Vector3(-0.8, 1.35, 0), Vector3(0.3, 2.7, 0.3)], [Vector3(0.8, 1.45, 0), Vector3(0.3, 2.6, 0.3)],
		[Vector3(0, 2.8, 0), Vector3(2.0, 0.3, 0.3)]],
	# The root wood Mine Prop piece the same way (F545: its one whole box was an invisible wall in the arch).
	"build/mine_prop__plank_root.glb": [[Vector3(-0.835, 1.35, 0), Vector3(0.29, 2.7, 0.36)],
		[Vector3(0.835, 1.35, 0), Vector3(0.29, 2.7, 0.36)], [Vector3(0, 2.845, 0), Vector3(1.96, 0.29, 0.36)]],
	"dungeon/rope_slide.glb": [[Vector3(0, 1.15, 0), Vector3(0.4, 2.3, 0.4)], [Vector3(0, -9.24, 18.873), Vector3(0.4, 2.0, 0.4)]],
	"dungeon/lift_winch.glb": [[Vector3(-1.15, 1.3, -0.6), Vector3(0.16, 2.6, 0.16)], [Vector3(-1.15, 1.3, 0.6), Vector3(0.16, 2.6, 0.16)]],
	# Brassgate Vault's forced vault door (handover Nov 22: "must be walkable"): its wall (2.1 m wide, 20 cm thick, flat
	# back at z -0.97) in bands round the round doorway (0.75 m round, middle 0.66 m up, flat at the floor: 1.4 m high,
	# measured on the model), each band's inner edge where the hole is widest in it, so no box covers the opening;
	# the wall above it; and the door disc swung wide open on the left. The 3 cm threshold has no box (you step over).
	"decor/bv_vault_door_forced.glb": [
		[Vector3(-0.79, 0.09, -0.873), Vector3(0.52, 0.18, 0.2)], [Vector3(0.79, 0.09, -0.873), Vector3(0.52, 0.18, 0.2)],
		[Vector3(-0.865, 0.28, -0.873), Vector3(0.37, 0.2, 0.2)], [Vector3(0.865, 0.28, -0.873), Vector3(0.37, 0.2, 0.2)],
		[Vector3(-0.89, 0.655, -0.873), Vector3(0.32, 0.55, 0.2)], [Vector3(0.89, 0.655, -0.873), Vector3(0.32, 0.55, 0.2)],
		[Vector3(-0.865, 1.03, -0.873), Vector3(0.37, 0.2, 0.2)], [Vector3(0.865, 1.03, -0.873), Vector3(0.37, 0.2, 0.2)],
		[Vector3(-0.79, 1.205, -0.873), Vector3(0.52, 0.15, 0.2)], [Vector3(0.79, 1.205, -0.873), Vector3(0.52, 0.15, 0.2)],
		[Vector3(-0.715, 1.355, -0.873), Vector3(0.67, 0.15, 0.2)], [Vector3(0.715, 1.355, -0.873), Vector3(0.67, 0.15, 0.2)],
		[Vector3(0, 1.725, -0.873), Vector3(2.1, 0.59, 0.2)],
		[Vector3(-0.86, 0.71, 0.1), Vector3(0.28, 1.42, 1.5)]],
	# Vigil of Orrin Stonejaw's spyhole wall (owner idea, Nov 22: peek at the boss through it): the wall block round its
	# clear hole (20 cm wide, 30 cm high, 0.9-1.2 m up, measured on the model), so you can look and shoot through it,
	# and the low stand-stone in front.
	"decor/vo_spyhole_wall.glb": [[Vector3(-0.35, 0.86, -0.19), Vector3(0.5, 1.72, 0.36)], [Vector3(0.35, 0.86, -0.19), Vector3(0.5, 1.72, 0.36)],
		[Vector3(0, 0.45, -0.19), Vector3(0.2, 0.9, 0.36)], [Vector3(0, 1.46, -0.19), Vector3(0.2, 0.52, 0.36)],
		[Vector3(0, 0.07, 0.25), Vector3(0.5, 0.14, 0.3)]],
}
## Things you walk through (small, up high, or traps whose moves come later).
const NO_BODY := ["decor/furn_wall_torch_iron.glb", "dungeon/trap_dart_plate.glb", "dungeon/chain_hanging.glb",
	"dungeon/recipe_scroll.glb", "treasure/tr_coins_wide.glb", "treasure/tr_chalice.glb",
	"decor/fossil_plaque.glb", "decor/rune_shield.glb",
	"build/ruin_rubble__cut_stone.glb", "dungeon/recipe_stand.glb", "dungeon/recipe_stand_stone.glb", "dungeon/rail_wedge.glb",
	"dungeon/rubble_ore.glb", "dungeon/lift_platform.glb", "dungeon/brace_old.glb"]  # (Lampwick's low rubble: you walk over it to the healing basin, owner Nov 20)

## Furniture you can smash (owner, decisions round 2: "a little root wood + small finds").
const SMASH := ["decor/crate_stack.glb", "decor/keg.glb", "props/barrel.glb", "decor/furn_barrel_rack.glb",
	"decor/grain_sacks.glb", "decor/shack_shelf.glb", "decor/shack_table.glb", "decor/shack_stool.glb", "decor/shack_bench.glb",
	"decor/furn_weapon_stand.glb", "decor/furn_whetstone.glb", "decor/furn_candle_stand.glb", "decor/furn_vase_tall.glb",
	"decor/furn_vase_wide.glb", "decor/furn_cauldron.glb", "decor/firewood_rack.glb", "decor/furn_banner_tall_1.glb",
	"decor/furn_banner_tall_2.glb"]
const DRIPS := ["dungeon/trap_drip_thin.glb", "dungeon/trap_drip_fat.glb", "dungeon/trap_drip_cluster.glb"]
const SMASH_HITS := 3
const RUBBLE_HITS := 4
const SMALL_FINDS := [["gold_coin", 2], ["rope", 1], ["bandage", 1], ["bolt_stone", 3], ["coal", 2]]
const SMALL_FIND_CHANCE := 0.35
const DRIP_DAMAGE := 50.0     ## a falling stalactite always hurts this much, armour or not (decisions round 2)
## Owner, Nov 20 ("must fall a lot faster, they never hurt me"): it used to take 1.6 s to come down from the Pillar
## Hall's 8 m rock, so you had walked 6 m on. Now a short crack, then it falls three times as hard (0.8 s in all), it
## aims at where you'll be (your walking speed), and it hurts anyone within DRIP_HIT of where it lands.
## Owner, Nov 20 (later): "they fall way too early, 5-8 m away. Only when I'm under them, and quick: stopped under
## one you take 50, sprinting away you barely make it and still take a little splash; 25 in the 3x3 m round it."
## So: no more aiming ahead; it lets go when you are right under it, and lands DRIP_WARN + DRIP_FALL later
## (sprinting at 6.5 m/s you are about 1.5 m on by then: the edge of the splash).
const DRIP_WARN := 0.1        ## seconds of dust and cracking before it lets go
const DRIP_FALL := 0.25       ## seconds it takes to come down (from any height)
const DRIP_PART_GAP := 0.08   ## a cluster's stalactites fall one by one, this far apart (each hurts on its own)
const DRIP_REACH := 0.9       ## step this close (sideways) under one and it falls
const DRIP_HIT := 0.75        ## right under it when it lands: DRIP_DAMAGE
const DRIP_SPLASH := 1.5      ## within the 3 x 3 m round it: DRIP_SPLASH_DAMAGE
const DRIP_SPLASH_DAMAGE := 25.0
const DRIP_LENGTH := 1.4      ## how far a stalactite's tip hangs below its base
const FLOOR_GIVE := 0.15      ## seconds a cracked floor tile holds you before it breaks (owner, Nov 20: quicker)
const FLOOR_FALL := 0.7       ## seconds its boards take to tumble down into the pit
## The crushers (owner, Nov 20: "make them work, fast, a bit hidden, instant kill"): each weight slams down CRUSH_DROP m
## in CRUSH_SLAM s, stays down, rises, waits up; the second one runs half a turn behind the first, so one is always up.
## Every computer runs them off the same clock (the computers' own time of day, which the internet keeps in step), so
## everyone sees the same; the host decides who is crushed.
## Owner, Nov 20 (3rd play): they hang in the Pack Hall now, 1 m higher (in a dark hole in its ceiling): they drop 2.5 m,
## slam fast and rise as fast as before (1.2 m a second). They wake only once someone has crossed the Pack Hall
## (CRUSH_WAKE_X), to block the way back; asleep, they hang still at the top.
const CRUSH_DROP := 2.5
const CRUSH_SLAM := 0.18
const CRUSH_DOWN := 0.6
const CRUSH_RISE := 2.5 / 1.2
const CRUSH_WAIT := 1.0
const CRUSH_CYCLE := CRUSH_SLAM + CRUSH_DOWN + CRUSH_RISE + CRUSH_WAIT
const CRUSH_HALF := Vector2(0.95, 0.55)  ## the weight's footprint (half sizes across and deep, in its own metres)
const CRUSH_WAKE_X := 68.0    ## someone this far across the Pack Hall (the dungeon's x, toward the loot door) wakes them
const CRUSH_ROOM := "pack_hall"
## The round door before the Pack Hall (owner, Nov 20, 3rd play): shut; E opens it and it swings toward you.
const USE_REACH := 3.0
## The Rune Shrine's healing basin (owner, Nov 20: "the fountain must heal"): stand by it and you heal this fast.
const HEAL_REACH := 2.5
const HEAL_RATE := 8.0        ## health a second
const HEAL_POOL := 30.0       ## owner, Nov 20: it heals 30 health in all, then it is dry until the dungeon refills
## The loot door opens when the Pack Hall's pack is dead (owner, Nov 20). It is a lock of DungeonKeys (the same saved,
## sent-to-everyone door state as the bigger dungeons' key doors); it shuts again when the pack moves back in.
const LIST_ID := {"mossgate": "mossgate_hold", "lampwick": "lampwick_drift", "pell": "old_pells_diggings", "mossprop": "mossprop_workings", "hald": "tomb_of_hald_ironbrow", "barrows": "the_quiet_barrows", "brassgate": "brassgate_vault"}  ## the dungeon's id in DungeonList / DungeonKeys
const PACK_LOCK := "pack"
const PACK_ROOM := "pack_hall"
const KILL := 1000000.0       ## instant death (more than any health and armour)
const THING_ID := 10000       ## a thing's id: dungeon index * THING_ID + its prop index in the plan
## F844 (owner, Nov 25): a signpost by every dungeon's way in: 1-3 skulls (small / medium / big), the picture of the
## recipe you find inside on its board, and a green tick once your group has learned it (builds/dungeon_signpost.py).
const SIGN_MODEL := "dungeon/signpost_skulls.glb"
const SIGN_BOARD := 1.0     ## the picture's centre height (= dungeon_signpost.BOARD_Y)
const SIGN_FRONT := 0.135   ## the board's front face (= dungeon_signpost.BOARD_FRONT)
const SIGN_PIC_X := -0.07   ## the picture sits left of the tick (= dungeon_signpost.PIC_X)
## Where it may stand, in the dungeon map's metres: sideways from the middle of the way in, and out from where the
## hole comes into the cave. The first spot with floor and open air wins. All lie inside the doorway's clear circle
## (CaveMaker._plan_dungeons: 4.5 m), so nothing the world grows stands in them; all keep 1 m off the 2.8 m path.
const SIGN_SPOTS := [Vector2(2.4, 1.5), Vector2(-2.4, 1.5), Vector2(2.7, 3.0), Vector2(-2.7, 3.0), Vector2(2.5, 0.6), Vector2(-2.5, 0.6)]
const SIGN_SKULLS := {"small": ["skull_mid"], "medium": ["skull_l", "skull_r"], "big": ["skull_l", "skull_mid", "skull_r"]}
const STONE := Color(0.5, 0.46, 0.41)
const WOOD := Color(0.45, 0.32, 0.2)

static var instance: DungeonBuild

var maker: CaveMaker
var built := 0  ## how many models were placed (tests)
var things := {}  ## id -> {kind, model, node: StaticBody3D, prop, d, centre: Vector3, landing: float}
var _applied := 0  ## how many of world_state.dungeon_broken this computer has shown
var _hits := {}    ## host: thing id -> hits so far
var _standing := {}  ## host: floor tile id -> seconds someone has stood on it
var _dead_at := {}   ## host: peer -> when we last killed them (no double kills while they respawn)
var _clock := 0.0
var _host_tick := 0.0
var _last_pos := {}  ## host: peer -> where they were at the last trap check (for their walking speed)
var _healed := {}    ## host: peer -> true while they stand by a healing basin (one message per visit)
var _room_alive := {}  ## host: "dungeon id/room" -> true while that room's creatures are alive (MonsterManager)
var heals: Array[Vector3] = []  ## the healing basins, in the world
var heal_ds: Array = []          ## the dungeon each basin is in (each keeps its own water)
var mine: MineTraps  ## Lampwick Drift's traps and lamps
var crushers: Array = []        ## thing ids of the crushers (each moves its weight every frame)
var ladders: Array[Vector3] = []  ## the plans' ladder pieces, in the world (Old Pell's shafts)
var ladder_tall: Array[float] = []  ## how tall each one is (a piece at scale 1.25 is 2.5 m: Mossprop's upper ladder)
var signs := {}  ## F844: dungeon list id -> its signpost (the tick shows once the recipe is learned)


## Is there a dungeon ladder at `pos` (a dwarf's feet)? The same reach as built ladders (Builder.ladder_at).
func ladder_at(pos: Vector3) -> bool:
	for i in ladders.size():
		var dd := pos - ladders[i]
		if Vector2(dd.x, dd.z).length() < 0.8 and dd.y > -0.5 and dd.y < ladder_tall[i] + 0.3:
			return true
	return false


static func load_plan(map_id: String) -> Dictionary:
	var path: String = PLANS.get(map_id, "")
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


## What a plan prop is: "smash", "rubble", "boulder", "drip", "floor" (breakable), "crusher", "door", "hand_door", "gate",
## "lever" (they move: built one by one) or "" (batched).
static func thing_kind(p: Dictionary) -> String:
	var model := String(p.model)
	var mk := MineTraps.kind_of(p)
	if mk != "":
		return mk
	if model in SMASH:
		return "smash"
	if model in DRIPS:
		return "drip"
	if model == "dungeon/trap_floor_break.glb" or (model == "dungeon/floor_loose_flagstone.glb" and p.get("role", "") == "trap"):
		return "floor"  # (Hald's fake floor: a loose stone slab over a spike pit, owner Nov 25)
	if model in ["dungeon/wall_broken.glb", "dungeon/wall_cracked.glb", "dungeon/wall_cracked_stone.glb"]:
		return "rubble"  # (the cracked wall in front of the hidden vault breaks like the rubble: owner, Nov 20)
	if model == "build/ruin_rubble__cut_stone.glb":
		return "rubble"  # (owner, Nov 20: the stone rubble in the Rubble Tunnel breaks, like the tower's)
	if model == "dungeon/trap_crusher.glb":
		return "crusher"
	if model == "dungeon/door_loot.glb":
		return "hand_door" if String(p.get("opens", "")) == "hand" else "door"
	if model == "dungeon/gate_round.glb" or model == "dungeon/gate_iron.glb":
		return "gate"  # (the way out's one-way gate: the lever behind it opens it, DungeonKeys)
	if model == "dungeon/lever.glb" or model == "dungeon/lever_iron.glb":
		return "lever"
	if model == "dungeon/portcullis.glb":
		return "portcullis"  # (Hald's Honour Chapel ambush, F843: it drops behind you, lifts when the room is won)
	if model.begins_with("cave/boulder_"):
		return "boulder"
	return ""


static func _xform(d: Dictionary, pos: Array, yaw_deg: float, scale: float, tilt_deg: float) -> Transform3D:
	var b := Basis(Vector3.UP, float(d.turn) * PI / 2.0 + deg_to_rad(yaw_deg)) * Basis(Vector3.RIGHT, deg_to_rad(tilt_deg))
	return Transform3D(b.scaled_local(Vector3.ONE * scale), DungeonMap.to_world(d, Vector3(pos[0], pos[1], pos[2])))


## Where each model goes in the world: {model path: [Transform3D, ...]} for one placed dungeon. `game` = only what
## the game draws in batches (no breakable things: built one by one; no chests: Storage boxes draw themselves).
static func placements(d: Dictionary, plan: Dictionary, game := false) -> Dictionary:
	var out := {}
	var add := func(model: String, t: Transform3D) -> void:
		if not out.has(model):
			out[model] = []
		out[model].append(t)
	for p in plan.get("pieces", []):
		var r := int(p.rot)
		var steps := r * 3 if r < 4 else r - 4
		add.call("build/%s__%s.glb" % [p.id, p.mat], _xform(d, p.pos, steps * 30.0, float(p.get("scale", 1.0)), 0.0))
	for p in plan.get("props", []):
		if game and (thing_kind(p) != "" or p.get("role", "") == "loot" or LootProps.is_lootable(p)):
			continue  # (breakables are built one by one; the recipe stand is a Storage box that draws itself; lootable decor: LootProps)
		add.call(String(p.model), _xform(d, p.pos, float(p.yaw), float(p.get("scale", 1.0)), float(p.get("tilt", 0.0))))
	if not game:
		for c in plan.get("chests", []):
			add.call("stations/%s.glb" % c.kind, _xform(d, c.pos, float(c.yaw), 1.0, 0.0))
	return out


func _ready() -> void:
	name = "DungeonBuild"
	instance = self
	mine = MineTraps.new()
	mine.db = self
	add_child(mine)
	for di in maker.dungeons.size():
		var d: Dictionary = maker.dungeons[di]
		var plan := load_plan(String(d.id))
		if plan.is_empty():
			push_warning("DungeonBuild: no plan for %s" % d.id)
			continue
		_build(d, plan)
		_build_things(di, d, plan)
		_build_sign(d)
		for p in plan.get("props", []):
			if p.get("role", "") == "heal":
				heals.append(DungeonMap.to_world(d, Vector3(p.pos[0], p.pos[1], p.pos[2])))
				heal_ds.append(d)
	_hook()


## Owner's play, Nov 20: the loot door and the lever did nothing. The game builds the dungeon BEFORE it makes the
## GameAuthority, so at _ready there was nobody to tell about the doors, the lever and the pack. Now this hooks in as
## soon as the authority (with its DungeonKeys and monsters) is there, at _ready or on a later frame.
var hooked := false
func _hook() -> void:
	var auth := GameAuthority.instance
	if hooked or auth == null or auth.keys == null or auth.monsters == null:
		return
	hooked = true
	auth.keys.door_changed.connect(_on_door_changed)
	auth.keys.gate_changed.connect(_on_gate_changed)
	auth.monsters.dungeon_room.connect(_on_dungeon_room)
	auth.learned_recipe.connect(func(_r: String): update_signs())
	update_signs()
	if auth.loot_props:
		for d in maker.dungeons:
			place_lootables(auth.loot_props, d, load_plan(String(d.id)))
	for id in things:
		var th: Dictionary = things[id]
		var t: Transform3D = th.xform
		if th.kind == "door":
			auth.keys.add_door(list_id(th.d), t.origin)
		elif th.kind == "lever":
			auth.keys.add_gate(list_id(th.d), t * Vector3(0, 1.05, 0.1))
	print("DUNGEON_BUILD hooked into the game (doors, gate lever, pack)")


## Everyone: the plan's lootable decor (role "lootable") goes to LootProps, keyed "d:<dungeon id>:<prop index>".
static func place_lootables(lp: LootProps, d: Dictionary, plan: Dictionary) -> void:
	var props: Array = plan.get("props", [])
	for i in props.size():
		var p: Dictionary = props[i]
		if LootProps.is_lootable(p):
			lp.place("d:%s:%d" % [d.id, i], String(p.model), _xform(d, p.pos, float(p.get("yaw", 0.0)), float(p.get("scale", 1.0)),
				float(p.get("tilt", 0.0))), String(p.get("label", "")))


func _exit_tree() -> void:
	if instance == self:
		instance = null


## F844: where this dungeon's signpost stands ({} when no spot fits): on the cave floor beside the way in, the board
## turned a little toward the path. The same on every computer (the cave and the dungeon come from the world number).
static func sign_spot(p_maker: CaveMaker, d: Dictionary) -> Dictionary:
	var mouth: Vector2 = d.map.mouth
	var door_y: float = (d.mouth as Vector3).y
	for s: Vector2 in SIGN_SPOTS:
		var w := DungeonMap.to_world(d, Vector3(mouth.x + s.x, 0.0, mouth.y + float(d.entry_out) + s.y))
		var fl := p_maker.find_floor(w.x, w.z, door_y + 2.5)
		if absf(fl.y - door_y) > 2.0:
			continue  # (a drop or a ledge there)
		var y := fl.y
		while y < fl.y + 0.3 and p_maker.sdf_at(Vector3(w.x, y + 0.05, w.z)) <= 0.0:
			y += 0.05  # (find_floor steps 0.25 m: come up to the real floor)
		var b := Basis(Vector3.UP, float(d.turn) * PI / 2.0 - signf(s.x) * deg_to_rad(25.0))
		var t := Transform3D(b, Vector3(w.x, y - 0.06, w.z))  # (the cairn's foot sits a little into the ground)
		if sign_clear(p_maker, t):
			return {xform = t, spot = s}
	return {}


## F844: is there open air all round the signpost (no rock through its post, board or skulls)?
static func sign_clear(p_maker: CaveMaker, t: Transform3D) -> bool:
	for h in [0.45, 1.0, 1.65]:
		for off in [Vector3.ZERO, Vector3(0.36, 0, 0), Vector3(-0.36, 0, 0), Vector3(0, 0, 0.25), Vector3(0, 0, -0.2)]:
			if p_maker.sdf_at(t * (off + Vector3(0, h, 0))) <= 0.05:
				return false
	return true


func _build_sign(d: Dictionary) -> void:
	var spot := sign_spot(maker, d)
	var scene := _scene(SIGN_MODEL)
	if spot.is_empty() or scene == null:
		return
	var info := DungeonList.get_dungeon(list_id(d))
	var sp := scene.instantiate() as Node3D
	sp.name = "Signpost_" + String(d.id)
	sp.transform = spot.xform
	add_child(sp)
	var shown: Array = SIGN_SKULLS.get(String(info.get("size", "small")), ["skull_mid"])
	for part in ["skull_l", "skull_mid", "skull_r"]:
		var n := sp.find_child(part, true, false) as Node3D
		if n:
			n.visible = part in shown
	var r: Dictionary = Recipes.LIST.get(String(info.get("recipe", "")), {})
	var tex: Texture2D = Items.icon(String(r.output)) if not r.is_empty() else null
	if tex:
		var pic := Sprite3D.new()  # the recipe's picture painted on the board
		pic.name = "Picture"
		pic.texture = tex
		pic.pixel_size = 0.28 / maxf(1.0, float(tex.get_width()))
		pic.shaded = true
		pic.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		pic.modulate = Color(0.92, 0.88, 0.8)  # (a little worn, like paint on old wood)
		pic.position = Vector3(SIGN_PIC_X, SIGN_BOARD, SIGN_FRONT + 0.006)
		sp.add_child(pic)
	var body := StaticBody3D.new()  # the post is solid (you bump into it, the pickaxe doesn't dig it)
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	sp.add_child(body)
	for box in [[Vector3(0, 0.8, 0), Vector3(0.22, 1.6, 0.22)], [Vector3(0, SIGN_BOARD, 0.09), Vector3(0.68, 0.42, 0.1)],
			[Vector3(0, 0.12, 0), Vector3(0.6, 0.24, 0.6)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box[1]
		cs.shape = bs
		cs.position = box[0]
		body.add_child(cs)
	sp.set_meta("recipe", String(info.get("recipe", "")))
	signs[list_id(d)] = sp
	_show_tick(sp)


## F844: the tick on each signpost shows once its recipe is learned (the host's world_state, sent to everyone).
func update_signs() -> void:
	for id in signs:
		_show_tick(signs[id])


func _show_tick(sp: Node3D) -> void:
	var tick := sp.find_child("tick", true, false) as Node3D
	if tick == null:
		return
	var auth := GameAuthority.instance
	var learned: Array = auth.world_state.get("learned", []) if auth else []
	tick.visible = String(sp.get_meta("recipe", "")) in learned


func _build(d: Dictionary, plan: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(d.id)
	add_child(root)
	var body := StaticBody3D.new()  # one body for every wall and floor: solid, and the pickaxe doesn't dig through it
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.add_to_group(RuinKit.GROUP)
	root.add_child(body)
	var all := placements(d, plan, true)
	for model in all:
		var scene := _scene(String(model))
		if scene == null:
			continue
		var xforms: Array = all[model]
		var inst := scene.instantiate() as Node3D
		var whole := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var rel := _rel_xform(inst, m)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = CameraFade.see_mesh(_own_mesh(m), lies_low(String(model)))  # (F766: walls fade like buildings)
			mm.instance_count = xforms.size()
			for i in xforms.size():
				mm.set_instance_transform(i, (xforms[i] as Transform3D) * rel)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			root.add_child(mmi)
			var box := rel * m.get_aabb()
			whole = box if first else whole.merge(box)
			first = false
		inst.free()
		built += xforms.size()
		if String(model) in NO_BODY or _is_flat_junk(String(model)):
			continue
		for t in xforms:
			_add_boxes(body, String(model), t as Transform3D, whole)
	for p in plan.get("props", []):  # (owner, Nov 20: the recipe stand is solid; its Storage box only draws it)
		if String(p.model).begins_with("dungeon/recipe_stand"):  # (Hald's is stone: recipe_stand_stone)
			_add_boxes(body, String(p.model), _xform(d, p.pos, float(p.yaw), 1.0, 0.0), AABB())
	for p in plan.get("pieces", []):  # (Old Pell's shafts: root wood ladders you climb like built ones)
		if p.id == "ladder":
			ladders.append(DungeonMap.to_world(d, Vector3(p.pos[0], p.pos[1], p.pos[2])))
			ladder_tall.append(Pieces.LIST.ladder.size.y * float(p.get("scale", 1.0)))
	# Torch light (it counts as light, so you heal by the torches: Darkness).
	for l in plan.get("lights", []):
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.68, 0.38)
		o.light_energy = float(d.map.get("torch_energy", 1.6))  # (the Tomb of Hald's are dimmer: F860)
		o.omni_range = float(d.map.get("torch_range", 9.0))
		o.position = DungeonMap.to_world(d, Vector3(l[0], l[1], l[2]))
		root.add_child(o)
		Darkness.mark(o)
	print("DUNGEON_BUILD %s: %d models placed" % [d.id, built])


## The breakable things, each its own body (meta "dungeon_thing" = its id) so it can be hit, shot and taken away.
func _build_things(di: int, d: Dictionary, plan: Dictionary) -> void:
	var props: Array = plan.get("props", [])
	for i in props.size():
		var p: Dictionary = props[i]
		var kind := thing_kind(p)
		if kind == "":
			continue
		var scene := _scene(String(p.model))
		if scene == null:
			continue
		var t := _xform(d, p.pos, float(p.yaw), float(p.get("scale", 1.0)), float(p.get("tilt", 0.0)))
		if p.has("stretch"):  # (Lampwick's tripwire: 1 m long, stretched to the tunnel's width)
			t.basis = t.basis.scaled_local(Vector3(float(p.stretch), 1.0, 1.0))
		var id := di * THING_ID + i
		var body := StaticBody3D.new()
		body.name = "Thing%d" % id
		body.collision_layer = World.TERRAIN_LAYER
		body.collision_mask = 0
		body.set_meta("dungeon_thing", id)
		add_child(body)
		var inst := scene.instantiate() as Node3D
		inst.transform = t
		body.add_child(inst)
		var whole := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var box := _rel_xform(inst, mi as Node3D) * (mi as MeshInstance3D).get_aabb()
			whole = box if first else whole.merge(box)
			first = false
		if not String(p.model) in NO_BODY or p.get("fires", false):
			_add_boxes(body, String(p.model), t, whole)
		if kind == "portcullis":  # (its gate's own box, marked so only it comes and goes)
			_add_boxes(body, String(p.model) + "#gate", t, whole)
			body.get_child(body.get_child_count() - 1).set_meta("gate", true)
		# (where a stalactite lands: the floor or bridge; Lampwick's upper level is 3 m up, its props say "floor")
		var landing := DungeonMap.to_world(d, Vector3(p.pos[0], float(p.get("floor", 0.0)) + 0.24, p.pos[2])).y
		things[id] = {kind = kind, model = String(p.model), node = body, prop = p, d = d, inst = inst, xform = t,
			centre = t * whole.get_center(), radius = whole.size.length() * 0.5 * float(p.get("scale", 1.0)), landing = landing}
		if MineTraps.kind_of(p) != "":
			mine.setup(id)
		if kind == "crusher":
			_make_crusher(id)
		elif kind == "door" and is_door_open(d):
			_open_door(id, false)
	_apply_broken()


func _scene(model: String) -> PackedScene:
	var path := "res://assets/models/" + model
	var scene := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if scene == null:
		push_warning("DungeonBuild: missing model %s" % path)
	return scene


## F766: floors, stairs, bridges, rails and junk on the ground: their part below his chest never fades
## (the floor he stands on, and the one in front of him).
static func lies_low(model: String) -> bool:
	var base := model.get_file().get_basename()
	if model.begins_with("build/"):
		return base.get_slice("__", 0) in CameraRoom.FLOORS
	for start in ["floor_", "bridge_", "rail_", "junk_", "lift_platform", "trap_floor", "trap_spikes", "trap_bear"]:
		if base.begins_with(start):
			return true
	return false


## A mesh with the model's own materials on it (overrides on the node, or the mesh's).
static func _own_mesh(m: MeshInstance3D) -> Mesh:
	var mesh := m.mesh
	if m.material_override or m.get_surface_override_material_count() > 0:
		mesh = mesh.duplicate()
		for s in mesh.get_surface_count():
			var mat: Material = m.material_override if m.material_override else m.get_surface_override_material(s)
			if mat:
				mesh.surface_set_material(s, mat)
	return mesh


## The model's collision boxes (BOXES, or the box round the whole model) on `body`. Also LootProps' (shared).
static func add_boxes(body: StaticBody3D, model: String, t: Transform3D, whole: AABB) -> void:
	_add_boxes(body, model, t, whole)


static func _add_boxes(body: StaticBody3D, model: String, t: Transform3D, whole: AABB) -> void:
	if model.get_file().begins_with("stairs__"):
		# F847 (owner, Nov 25: "all of the stairs are broken"): a building kit stairs (Hald's stone stairs) got the box
		# round the whole model: a 2 m block, you stood on air at its top and bumped its sides. Now the same slanted
		# slab you walk up as the stairs you build (PieceNode.stairs_slope).
		var cs := CollisionShape3D.new()
		cs.shape = PieceNode.stairs_slope(Pieces.LIST.stairs.size * t.basis.get_scale(), false)
		cs.transform = Transform3D(t.basis.orthonormalized(), t.origin)
		cs.set_meta("surface", "stone")
		body.add_child(cs)
		return
	var boxes: Array = BOXES.get(model, [[whole.get_center(), whole.size]])
	for bx in boxes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		var sc := t.basis.get_scale()
		sh.size = ((bx[1] as Vector3) * sc).abs()
		cs.shape = sh
		cs.transform = Transform3D(t.basis.orthonormalized(), t * (bx[0] as Vector3))
		cs.set_meta("surface", surface_of(model))  # (what a running dwarf kicks up here, F775)
		body.add_child(cs)


## What a dungeon model's floor is made of, for footstep dust (F775): "wood" or "stone".
static func surface_of(model: String) -> String:
	for w in ["plank", "bridge", "lift_platform", "beam", "brace", "wood"]:
		if model.contains(w):
			return "wood"
	return "stone"


## Dungeon junk (owner, Nov 20: "just for looks", low and flat) and small treasure bits: you walk over them, so they
## get no body (a 5 cm box would trip you). Reused crates, sacks and barrels keep theirs (they smash).
static func _is_flat_junk(model: String) -> bool:
	return model.begins_with("dungeon/junk_") or model.begins_with("treasure/tr_")


static func _rel_xform(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			t = (c as Node3D).transform * t
		c = c.get_parent()
	return t


## The thing a collider belongs to (-1 = none).
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("dungeon_thing"):
		return int((collider as Node).get_meta("dungeon_thing"))
	return -1


# ================================================================== breaking things (request -> host -> everyone)

## Our swing (or bolt: `by_bolt`) hit thing `id`.
func ask_hit(id: int, by_bolt := false) -> void:
	var auth := GameAuthority.instance
	if auth == null:
		return
	if auth.is_host():
		request_hit(auth.local_peer_id(), id, by_bolt)
	else:
		_rpc_hit.rpc_id(1, id, by_bolt)


@rpc("any_peer", "reliable")
func _rpc_hit(id: int, by_bolt: bool) -> void:
	var auth := GameAuthority.instance
	if auth and auth.is_host():
		request_hit(multiplayer.get_remote_sender_id(), id, by_bolt)


## Host: a hit on a thing. Smashing furniture: SMASH_HITS hits, then a little root wood and maybe a small find.
## The hidden boulder: exactly like a cave boulder (stone every hit, Boulders.HITS hits, then it bursts). A bolt that
## hits a stalactite brings it down.
func request_hit(peer_id: int, id: int, by_bolt := false) -> void:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	var th: Dictionary = things.get(id, {})
	if ps == null or th.is_empty() or is_broken(id):
		return
	var at: Vector3 = th.centre
	if mine.on_hit(peer_id, id, by_bolt):
		return
	if th.kind == "drip":
		if by_bolt:
			_fall(id)
		return
	if by_bolt or th.kind in ["floor", "crusher", "door", "hand_door", "gate", "lever", "portcullis"]:
		return
	var chest := ps.node.global_position + Vector3.UP * 1.1
	if chest.distance_to(at) > GameAuthority.REACH + float(th.radius) + 0.5:
		return
	var out := (chest - at).normalized()
	var hits: int = _hits.get(id, 0) + 1
	_hits[id] = hits
	match String(th.kind):
		"boulder":  # (owner, Nov 20: ANY hit breaks it: pickaxe, axe, any weapon; the pickaxe gets more stone)
			var pick := Items.kind(ps.selected_item()) == "pickaxe"
			auth.spawn_drop("stone", 2 if pick else 1, at + out * 1.6 + Vector3.UP * 0.3)
			auth.give_xp(peer_id, 1, "mining")
			if hits >= Boulders.HITS:
				auth._tell_feedback(peer_id, {state = "dug", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out, boulder = true})
				_break(id)
			else:
				auth._tell_feedback(peer_id, {state = "hit", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out})
		"rubble":
			var wood: bool = th.model == "dungeon/wall_cracked.glb"  # (boards: wood, owner Nov 20)
			auth.spawn_drop("rootwood" if wood else "stone", 1, at + out * 0.8 + Vector3.UP * 0.3)
			if hits >= RUBBLE_HITS:
				_break(id)
			else:
				_ev_hit.rpc(id)
		_:
			if hits >= SMASH_HITS:
				auth.spawn_drop("rootwood", randi_range(1, 2), at + out * 0.5 + Vector3.UP * 0.3)
				if randf() < SMALL_FIND_CHANCE:
					var f: Array = SMALL_FINDS.pick_random()
					auth.spawn_drop(String(f[0]), int(f[1]), at + out * 0.5 + Vector3.UP * 0.5)
				_break(id)
			else:
				_ev_hit.rpc(id)


## F603: a monster's attack lands — break nearby smash/rubble props without a player distance check.
func request_monster_hit(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty() or is_broken(id) or th.kind in ["floor", "crusher", "door", "hand_door", "gate", "lever", "portcullis", "drip", "boulder"]:
		return
	var auth := GameAuthority.instance
	var at: Vector3 = th.centre
	var hits: int = _hits.get(id, 0) + 1
	_hits[id] = hits
	if th.kind == "rubble":
		if hits >= RUBBLE_HITS:
			_break(id)
		else:
			_ev_hit.rpc(id)
	else:
		if hits >= SMASH_HITS:
			auth.spawn_drop("rootwood", randi_range(1, 2), at + Vector3.UP * 0.3)
			if randf() < SMALL_FIND_CHANCE:
				var f: Array = SMALL_FINDS.pick_random()
				auth.spawn_drop(String(f[0]), int(f[1]), at + Vector3.UP * 0.5)
			_break(id)
		else:
			_ev_hit.rpc(id)


## Host: thing `id` is gone for good (saved; friends who join see it gone too).
func _break(id: int) -> void:
	var auth := GameAuthority.instance
	_hits.erase(id)
	var list: Array = auth.world_state.get("dungeon_broken", []).duplicate()
	if id in list:
		return
	list.append(id)
	auth.world_state["dungeon_broken"] = list
	_ev_broke.rpc(id)
	auth._ev_state.rpc(auth.world_state)


func is_broken(id: int) -> bool:
	var auth := GameAuthority.instance
	return auth != null and id in auth.world_state.get("dungeon_broken", [])


@rpc("authority", "call_local", "reliable")
func _ev_hit(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty():
		return
	# (owner, Nov 20, 3rd play: the cracked wall showed stone dust; it is boards: wood splinters)
	var stone: bool = th.kind != "smash" and th.model != "dungeon/wall_cracked.glb"
	Fx.burst(get_parent(), th.centre, STONE if stone else WOOD, 8 if stone else 14, 2.5)
	Sfx.play("dig_rock" if stone else "chop", th.centre, -3.0)


## Everyone: thing `id` breaks now (with its burst / fall).
@rpc("authority", "call_local", "reliable")
func _ev_broke(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty() or th.get("gone", false):
		return
	if mine.on_broke(id):
		return
	match String(th.kind):
		"boulder":  # exactly like a cave boulder breaking (Boulders.set_broken)
			var mid: Vector3 = th.centre
			var sc := float(th.prop.get("scale", 1.0))
			RockShatter.burst(get_parent(), mid + Vector3.UP * 0.2 * sc, Vector3.UP, Boulders.STONE, Mat.STONE)
			RockShatter.burst(get_parent(), mid, Vector3(1, 0.5, 0), Boulders.STONE, Mat.STONE)
			if sc > 2.5:
				RockShatter.burst(get_parent(), mid - Vector3.UP * 0.2 * sc, Vector3(-1, 0.5, 0.3), Boulders.STONE, Mat.STONE)
		"rubble":
			if th.model == "dungeon/wall_cracked.glb":  # its split boards burst out, fall over and lie on the floor
				Fx.burst(get_parent(), th.centre, WOOD, 28, 3.5)
				Sfx.play("chop", th.centre, 2.0, 0.7)
				_topple(id)
				return
			if th.model == "dungeon/wall_cracked_stone.glb":  # (Hald's, F857) its stones burst out and tumble down
				RockShatter.burst(get_parent(), th.centre, Vector3.UP, STONE, Mat.STONE)
				Sfx.play("dig_rock", th.centre, 2.0, 0.7)
				_topple(id)
				return
			RockShatter.burst(get_parent(), th.centre, Vector3.UP, STONE, Mat.STONE)
		"floor":  # (owner, Nov 20: "no break animation"): the boards snap and tumble down into the spike pit
			var stone := String(th.prop.model) == "dungeon/floor_loose_flagstone.glb"  # (Hald's slab cracks like stone)
			Fx.burst(get_parent(), th.centre, STONE if stone else WOOD, 24, 3.0, Vector3.DOWN)
			Sfx.play("dig_break" if stone else "chop", th.centre, 2.0, 0.6)
			_tumble(id, 4.4, FLOOR_FALL)
			return
		"drip":
			_drop_drip(id)
			return
		_:
			Fx.burst(get_parent(), th.centre, WOOD, 16, 3.0)
			Sfx.play("chop", th.centre, 0.0, 0.8)
	_hide(id)


func _hide(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty() or th.get("gone", false):
		return
	if mine.show_spent(id):
		return  # (a sprung mine trap stays where it is: the cart at its stopper, the jaws shut...)
	th.gone = true
	if th.kind == "drip":  # (its rock stays on the ceiling; its stones are gone)
		for part in _parts(th.node):
			(part as Node3D).visible = false
		for c in (th.node as Node).get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		return
	(th.node as Node).queue_free()


## Everyone: thing `id`'s parts come loose and fall `depth` m, turning over (the spike pit's boards, the cracked
## wall's boards). Its body stops at once; the parts are gone when they land.
func _tumble(id: int, depth: float, secs: float) -> void:
	var th: Dictionary = things[id]
	th.gone = true
	var body: StaticBody3D = th.node
	for c in body.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	var rng := RandomNumberGenerator.new()
	rng.seed = id
	var out := Vector3.ZERO
	if th.model in ["dungeon/wall_cracked.glb", "dungeon/wall_cracked_stone.glb"]:  # (it bursts out of the wall's face, into the room)
		out = (th.xform as Transform3D).basis.z.normalized()
	var parts := (th.inst as Node).find_children("*", "MeshInstance3D", true, false)
	for k in parts.size():
		var part := parts[k] as Node3D
		var g := part.global_transform
		var axis := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1)).normalized()
		var turn := rng.randf_range(2.0, 5.0) * secs
		var wait := rng.randf_range(0.0, 0.12) + (0.1 if String(part.name) == "frame" else 0.0)
		var push := out * rng.randf_range(0.4, 1.2) + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var tw := create_tween()
		tw.tween_interval(wait)
		tw.tween_method(func(f: float) -> void:
			if is_instance_valid(part):
				part.global_transform = Transform3D(g.basis.rotated(axis, turn * f), g.origin + push * f - Vector3.UP * depth * f * f), 0.0, 1.0, secs)
		tw.tween_callback(func() -> void:
			if is_instance_valid(part):
				part.hide())
	get_tree().create_timer(secs + 0.4).timeout.connect(_free_later.bind(body))


## (a method, not a lambda: if the dungeon itself is gone first, e.g. in tests, the timer just does nothing)
func _free_later(n: Object) -> void:
	if is_instance_valid(n):
		(n as Node).queue_free()


const TOPPLE_LIE := 4.0  ## seconds the cracked wall's fallen boards lie on the floor before they sink away


## Everyone: the cracked wall's boards come loose (owner, Nov 20, 3rd play: "it just vanishes; I want splinters and
## boards falling down like the floor tiles"). Each board bursts out of the wall, tips over and falls onto the floor
## (really falling: the higher ones take longer), lies there a few seconds, then sinks away. Its body goes at once.
func _topple(id: int) -> void:
	var th: Dictionary = things[id]
	th.gone = true
	var body: StaticBody3D = th.node
	for c in body.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	var rng := RandomNumberGenerator.new()
	rng.seed = id
	var t: Transform3D = th.xform
	var out := t.basis.z.normalized()
	var side := t.basis.x.normalized()
	var floor_y := float(th.landing)
	var longest := 0.0
	for mi in (th.inst as Node).find_children("*", "MeshInstance3D", true, false):
		var part := mi as MeshInstance3D
		var g := part.global_transform
		var lc := part.get_aabb().get_center()
		var c := g * lc  # (it turns about its own middle, which falls until the board lies on the floor)
		var drop := maxf(0.05, c.y - floor_y - 0.05)
		var secs := clampf(sqrt(2.0 * drop / 9.8), 0.25, 0.7) + 0.15
		var wait := rng.randf_range(0.0, 0.15)
		longest = maxf(longest, wait + secs)
		var push := out * rng.randf_range(0.5, 1.3) + side * rng.randf_range(-0.3, 0.3)
		var lie := deg_to_rad(rng.randf_range(78.0, 92.0))  # it tips over outward (about the wall's line) and lies flat
		var spin := rng.randf_range(-0.6, 0.6)
		var tw := create_tween()
		tw.tween_interval(wait)
		tw.tween_method(func(f: float) -> void:
			if is_instance_valid(part):
				var b := g.basis.rotated(side, lie * minf(1.0, f * 1.15)).rotated(Vector3.UP, spin * f)
				part.global_transform = Transform3D(b, c + push * f - Vector3.UP * drop * f * f - b * lc), 0.0, 1.0, secs)
		tw.tween_callback(func() -> void:
			if is_instance_valid(part):
				Fx.burst(get_parent(), part.global_position, WOOD, 5, 1.2)
				Sfx.play("chop", part.global_position, -6.0, 1.3))
		tw.tween_interval(TOPPLE_LIE + rng.randf_range(0.0, 1.0))
		tw.tween_method(func(f: float) -> void:
			if is_instance_valid(part):
				part.scale = Vector3.ONE * (1.0 - f * 0.9), 0.0, 1.0, 1.0)
		tw.tween_callback(func() -> void:
			if is_instance_valid(part):
				part.hide())
	get_tree().create_timer(longest + TOPPLE_LIE + 2.5).timeout.connect(_free_later.bind(body))


## Show what the host says is broken (on loading, joining, or after a change).
func _apply_broken() -> void:
	var auth := GameAuthority.instance
	if auth == null:
		return
	var list: Array = auth.world_state.get("dungeon_broken", [])
	if list.size() == _applied:
		return
	_applied = list.size()
	for id in list:
		_hide(int(id))


# ================================================================== stalactites and the spike pit's floor

## Host: a stalactite lets go (someone walked under it, or a bolt hit it).
func _fall(id: int) -> void:
	if is_broken(id):
		return
	_break(id)
	var th: Dictionary = things[id]
	var parts := _parts(th.node)
	var land_t := drip_time(th)
	var hurt_once := {}
	for k in parts.size():
		get_tree().create_timer(land_t + k * DRIP_PART_GAP).timeout.connect(_drip_lands.bind(id, hurt_once))


## Host: a falling stalactite reaches the floor: whoever stands under it is hurt (once per stalactite).
func _drip_lands(id: int, hurt_once: Dictionary) -> void:
	var auth := GameAuthority.instance
	var th: Dictionary = things.get(id, {})
	if auth == null or th.is_empty():
		return
	var c: Vector3 = th.centre
	for pid in auth.players:
		var p: Vector3 = auth.players[pid].node.global_position
		var dmg := drip_damage(th, p)
		if hurt_once.has(pid) or dmg <= 0.0:
			continue
		hurt_once[pid] = true
		auth.hurt(pid, dmg, {pierce = true})  # (armour doesn't help)


## How much a stalactite landing now hurts someone at `p`: 50 right under it, 25 in the 3 x 3 m round it, else 0.
func drip_damage(th: Dictionary, p: Vector3) -> float:
	var c: Vector3 = th.centre
	if p.y < float(th.landing) - 1.0 or p.y > c.y:
		return 0.0
	if Vector2(p.x - c.x, p.z - c.z).length() <= DRIP_HIT:
		return DRIP_DAMAGE
	var q := DungeonMap.to_local(th.d, p) - DungeonMap.to_local(th.d, c)  # (the square lines up with the rooms)
	return DRIP_SPLASH_DAMAGE if absf(q.x) <= DRIP_SPLASH and absf(q.z) <= DRIP_SPLASH else 0.0


## Everyone: dust and a crack, then the stalactite (a cluster: each of its parts, one after another) drops.
func _drop_drip(id: int) -> void:
	var th: Dictionary = things[id]
	th.gone = true
	var body: StaticBody3D = th.node
	for c in body.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	var top: Vector3 = th.centre
	Fx.burst(get_parent(), top, STONE, 10, 1.5, Vector3.DOWN)
	Sfx.play("dig_break", top, -22.0, 0.6)  # the crack as it lets go (owner, Nov 20: "too much sound": quieter)
	var parts := _parts(body)
	for k in parts.size():
		var part: Node3D = parts[k]
		var y0 := part.global_position.y
		var drop := maxf(0.5, y0 - DRIP_LENGTH - float(th.landing))
		var tw := create_tween()
		tw.tween_interval(drip_warn(th) + k * DRIP_PART_GAP)
		tw.tween_property(part, "global_position:y", y0 - drop, drip_fall(th)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var loud := k == 0  # (one thud per stalactite, not one per stone of a cluster: owner, Nov 20, "too much sound")
		tw.tween_callback(func() -> void:
			RockShatter.burst(get_parent(), part.global_position, Vector3.UP, STONE, Mat.STONE, 0.6)
			if loud:
				Sfx.play("thud", part.global_position, -18.0, 0.9)  # (owner, Nov 20: a real recorded rock thud)
			part.visible = false)


## A stalactite model's falling stones ("stone", or a cluster's "stone0".."stone4"); its "rock" stays on the ceiling.
static func _parts(body: Node) -> Array:
	var out := []
	for mi in body.find_children("stone*", "MeshInstance3D", true, false):
		out.append(mi)
	out.sort_custom(func(a, b): return String(a.name) < String(b.name))
	return out


# ================================================================== host: traps that watch where you stand

func _physics_process(delta: float) -> void:
	_clock += delta
	if not hooked:
		_hook()
	_apply_broken()
	var auth := GameAuthority.instance
	var now := Time.get_unix_time_from_system()
	for id in crushers:
		_move_crusher(id, now, auth)
	mine.step(delta)
	for id in things:  # (a friend who joins gets the doors with the world state: show them as the host has them)
		_sync_doors(id)
	if auth == null or not auth.is_host():
		return
	_host_tick -= delta
	if _host_tick > 0.0:
		return
	var step := 0.1
	_host_tick = step
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null:
			continue
		var p := node.global_position
		_check_deadly_drop(auth, pid, p)
		_check_heal(auth, pid, p, step)
		_check_crushers_wake(auth, p)
		mine.host_check(auth, pid, p, step)
		for id in things:
			var th: Dictionary = things[id]
			if th.get("gone", false) or is_broken(id):
				continue
			var c: Vector3 = th.centre
			var flat := Vector2(p.x - c.x, p.z - c.z).length()
			if th.kind == "drip" and p.y < c.y and p.y > float(th.landing) - 1.0:
				if flat < DRIP_REACH:  # (right under it: owner, Nov 20)
					_fall(id)
			elif th.kind == "floor":
				var q := DungeonMap.to_local(th.d, p)
				var tile: Array = th.prop.pos
				var up := q.y - float(tile[1])  # (above the tile itself: Old Pell's boards are 6 m down, owner Nov 20)
				if absf(q.x - float(tile[0])) < 1.0 and absf(q.z - float(tile[2])) < 1.0 and up > -0.3 and up < 0.9:
					_standing[id] = float(_standing.get(id, 0.0)) + step
					if _standing[id] >= FLOOR_GIVE:
						_standing.erase(id)
						_break(id)


	_traps_hit_creatures(auth)
	_check_portcullises(auth)


## Host: traps hurt creatures too (decisions round 2: "you can lure creatures into traps"). Owner, Nov 20 (3rd play):
## the loot door never opened: creatures that chased you onto the bridge fell into the chasm and lived on down there,
## so the Pack Hall's pack was never all dead. Now the spikes and the crushers kill them like they kill you.
func _traps_hit_creatures(auth: GameAuthority) -> void:
	var mm := auth.monsters
	if mm == null:
		return
	for m in mm.monsters.values():
		var mon := m as Monster
		if mon == null or not mon.is_alive():
			continue
		var at := mon.global_position
		for d in maker.dungeons:
			if not DungeonMap.near_box(d, at, 2.0):
				continue
			var why := deadly_space(d, at)
			if why == "" and _under_crusher(at):
				why = "crusher"
			if why != "":
				print("DUNGEON %s: a %s died in the %s" % [d.id, mon.kind, why])
				mm._kill(mon, 0)
				break


## Is `p` under (or right beside) a crusher's weight, awake or not? Creatures never step there (owner, Nov 20).
func near_crusher(p: Vector3) -> bool:
	for id in crushers:
		var q := (things[id].xform as Transform3D).affine_inverse() * p
		if absf(q.x) < CRUSH_HALF.x + 0.5 and absf(q.z) < CRUSH_HALF.y + 0.5:
			return true
	return false


## Is `p` under a crusher's weight while it slams (the moment that kills)?
func _under_crusher(p: Vector3) -> bool:
	var now := Time.get_unix_time_from_system()
	for id in crushers:
		var th: Dictionary = things[id]
		if not crushers_awake(th.d):
			continue
		var t := now - int(th.turn) * CRUSH_CYCLE * 0.5
		if not crushing(t):
			continue
		var q := (th.xform as Transform3D).affine_inverse() * p
		var bottom := float(th.landing) + (CRUSH_DROP + 0.1) * (1.0 - crush_down(t))
		if absf(q.x) < CRUSH_HALF.x + 0.3 and absf(q.z) < CRUSH_HALF.y + 0.3 and p.y < bottom and p.y > float(th.landing) - 1.0:
			return true
	return false


## Host: below the floor of the chasm or the spike pit (a space whose floor is under 0) = on the spikes: dead.
func _check_deadly_drop(auth: GameAuthority, pid: int, p: Vector3) -> void:
	if _clock - float(_dead_at.get(pid, -100.0)) < 5.0:
		return
	for d in maker.dungeons:
		var pit := deadly_space(d, p)
		if pit != "":
			_dead_at[pid] = _clock
			print("DUNGEON %s: player %d fell into the %s" % [d.id, pid, pit])
			auth.hurt(pid, KILL)
			return


## Seconds from letting go to landing, for a stalactite thing.
func drip_time(th: Dictionary) -> float:
	return drip_warn(th) + drip_fall(th)


## A plan's stalactite may take its own time (owner, Nov 20, Lampwick: "they fall way too fast"; Mossgate keeps its own).
static func drip_warn(th: Dictionary) -> float:
	return float(th.prop.get("warn", DRIP_WARN))


static func drip_fall(th: Dictionary) -> float:
	return float(th.prop.get("fall", DRIP_FALL))


## Host: standing by the Rune Shrine's healing basin heals you (owner, Nov 20).
func _check_heal(auth: GameAuthority, pid: int, p: Vector3, step: float) -> void:
	var near := false
	var key := "dungeon_basin"
	for i in heals.size():
		var h := heals[i]
		if Vector2(p.x - h.x, p.z - h.z).length() < HEAL_REACH and absf(p.y - h.y) < 2.0:
			near = true
			key = basin_key(heal_ds[i])
	var ps := auth.get_player(pid)
	if not near or ps == null:
		_healed.erase(pid)
		return
	# Its water heals HEAL_POOL in all (everyone together), then it is dry until the dungeon refills (saved).
	var st: Dictionary = auth.world_state.get(key, {used = 0.0, at = 0.0}).duplicate()
	var played := float(auth.world_state.get("played", 0.0))
	if float(st.used) >= HEAL_POOL and played - float(st.at) >= DungeonLoot.REFILL:
		st.used = 0.0
	var left := HEAL_POOL - float(st.used)
	var missing := ps.vitals.max_health() - ps.vitals.health
	if left <= 0.0:
		if not _healed.has(pid):
			auth.tell(pid, "The basin is dry.")
		_healed[pid] = true
		return
	if missing <= 0.0:
		return
	var amount := minf(HEAL_RATE * step, minf(left, missing))
	auth.heal(pid, amount)  # (their own computer owns their health: it stops at full)
	st.used = float(st.used) + amount
	if float(st.used) >= HEAL_POOL:
		st.at = played
		auth.tell(pid, "The basin's last water is gone.")
	auth.world_state[key] = st
	if not _healed.has(pid):
		auth.tell(pid, "The basin's cool water mends your wounds.")
	_healed[pid] = true


## Each dungeon's basin keeps its own water (Mossgate's key from before Lampwick stays the same).
static func basin_key(d: Dictionary) -> String:
	return "dungeon_basin" if String(d.id) == "mossgate" else "dungeon_basin_" + String(d.id)


# ================================================================== the crushers

## A crusher's weight gets its own moving box (it slams down onto you, and you can't walk through it while it's down).
func _make_crusher(id: int) -> void:
	var th: Dictionary = things[id]
	var weight := (th.inst as Node).find_child("weight", true, false) as Node3D
	if weight == null:
		push_warning("DungeonBuild: crusher model has no weight part")
		return
	th.weight = weight
	th.rest_y = weight.position.y
	th.turn = crushers.size()  # (the second crusher runs half a turn behind the first)
	th.down = 0.0
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.82, 1.15, 1.02)
	cs.shape = sh
	cs.position = Vector3(0, 2.07, 0)
	body.add_child(cs)
	weight.add_child(body)
	crushers.append(id)


## How far down a crusher's weight is at time t (0 = up, 1 = on the floor), and whether it is slamming right now.
static func crush_down(t: float) -> float:
	t = fposmod(t, CRUSH_CYCLE)
	if t < CRUSH_SLAM:
		return pow(t / CRUSH_SLAM, 2.0)
	t -= CRUSH_SLAM
	if t < CRUSH_DOWN:
		return 1.0
	t -= CRUSH_DOWN
	if t < CRUSH_RISE:
		return 1.0 - t / CRUSH_RISE
	return 0.0


static func crushing(t: float) -> bool:
	return fposmod(t, CRUSH_CYCLE) < CRUSH_SLAM + 0.1  # (the slam, and the moment it hits the floor)


## Have this dungeon's crushers woken up (someone crossed the Pack Hall)? Kept in world_state.dungeon_awake (saved,
## sent to everyone).
func crushers_awake(d: Dictionary) -> bool:
	if d.map.get("crushers_always", false):
		return true  # (Old Pell's Deep Seam: they never sleep)
	var auth := GameAuthority.instance
	return auth != null and String(d.id) in auth.world_state.get("dungeon_awake", [])


## Host: someone at `p` far enough across the Pack Hall (or past it) wakes that dungeon's crushers.
func _check_crushers_wake(auth: GameAuthority, p: Vector3) -> void:
	for d in maker.dungeons:
		if crushers_awake(d) or not DungeonMap.near_box(d, p, 0.0):
			continue
		var room := DungeonMap.space_at(d, p)
		var q := DungeonMap.to_local(d, p)
		if (room == CRUSH_ROOM and q.x > CRUSH_WAKE_X) or room in ["loot_door", "loot_room"]:
			set_crushers_awake(d, true)


## Host: wake (or put back to sleep) a dungeon's crushers, for everyone.
func set_crushers_awake(d: Dictionary, awake: bool) -> void:
	var auth := GameAuthority.instance
	var list: Array = auth.world_state.get("dungeon_awake", []).duplicate()
	if (String(d.id) in list) == awake:
		return
	if awake:
		list.append(String(d.id))
		print("DUNGEON %s: the crushers wake up" % d.id)
		for pid in auth.players:
			if DungeonMap.near_box(d, auth.players[pid].node.global_position, 5.0):
				auth.tell(pid, "Behind you, something heavy starts to thunder.")
	else:
		list.erase(String(d.id))
	auth.world_state["dungeon_awake"] = list
	auth._ev_state.rpc(auth.world_state)


## Everyone: move a crusher's weight; the host crushes whoever is under it while it slams down. Asleep, it hangs up.
func _move_crusher(id: int, now: float, auth: GameAuthority) -> void:
	var th: Dictionary = things[id]
	if not th.has("weight"):
		return
	var t := now - int(th.turn) * CRUSH_CYCLE * 0.5
	var down := crush_down(t) if crushers_awake(th.d) else 0.0
	var w: Node3D = th.weight
	w.position.y = float(th.rest_y) - CRUSH_DROP * down
	if down >= 1.0 and float(th.down) < 1.0:  # it hits the floor
		var at: Vector3 = (th.xform as Transform3D).origin
		var me := auth.get_player(auth.local_peer_id()) if auth else null
		if me and me.node and me.node.global_position.distance_to(at) < 14.0:  # (owner, Nov 20: only close by, in its room)
			Sfx.play("thud", at + Vector3.UP * 0.3, -3.0, 0.7, 14.0)
			Fx.burst(get_parent(), at + Vector3.UP * 0.1, STONE, 10, 2.0)
	th.down = down
	if auth == null or not auth.is_host() or not crushing(t) or not crushers_awake(th.d):
		return
	var inv := (th.xform as Transform3D).affine_inverse()
	var bottom := float(th.landing) + (CRUSH_DROP + 0.1) * (1.0 - down)  # (the weight's spiked bottom, above the floor)
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null or _clock - float(_dead_at.get(pid, -100.0)) < 5.0:
			continue
		var q := inv * node.global_position
		var p := node.global_position
		if absf(q.x) < CRUSH_HALF.x + 0.3 and absf(q.z) < CRUSH_HALF.y + 0.3 and p.y < bottom and p.y > float(th.landing) - 1.0:
			_dead_at[pid] = _clock
			print("DUNGEON: player %d crushed" % pid)
			auth.hurt(pid, KILL)


# ================================================================== the loot door (opens when the pack is dead)

static func list_id(d: Dictionary) -> String:
	return String(LIST_ID.get(String(d.id), String(d.id)))


func is_door_open(d: Dictionary) -> bool:
	var auth := GameAuthority.instance
	return auth != null and auth.keys != null and auth.keys.is_open(list_id(d))


## Host: a dungeon room's creatures came, or were all killed (MonsterManager). The Pack Hall's pack dead = the loot door
## opens; the pack moving back in (an hour later) = it shuts again.
func _on_dungeon_room(dungeon_id: String, room: String, cleared: bool) -> void:
	_room_alive[dungeon_id + "/" + room] = not cleared  # (a portcullis room: the gate lifts once it is won)
	var auth := GameAuthority.instance
	if auth == null or not auth.is_host() or auth.keys == null or room != PACK_ROOM:
		return
	for d in maker.dungeons:
		if String(d.id) == dungeon_id:
			auth.keys.set_lock(list_id(d), PACK_LOCK, cleared)
			if not cleared:
				set_crushers_awake(d, false)  # (the pack moved back in: the crushers wait for the next crossing)
			if cleared:
				for pid in auth.players:
					if DungeonMap.near_box(d, auth.players[pid].node.global_position, 5.0):
						auth.tell(pid, "With the pack dead, a heavy door grinds open somewhere nearby.")


## Everyone: show door/gate thing `id` as the world state has it (on loading, a friend joining, or a change).
func _sync_doors(id: int) -> void:
	var th: Dictionary = things[id]
	var want := false
	match String(th.kind):
		"door":
			want = is_door_open(th.d)
		"hand_door":
			want = opened_by_hand(id) != 0
		"gate":
			want = is_gate_open(th.d)
		"portcullis":
			if not th.has("open") or bool(th.open) == is_portcullis_shut(id):
				_move_portcullis(id, not is_portcullis_shut(id), false)
			return
		"lever":  # (its handle follows the gate: down while the gate is open)
			if bool(th.get("open", false)) != is_gate_open(th.d):
				th.open = is_gate_open(th.d)
				_pull_lever(id, th.open)
			return
		_:
			return
	if bool(th.get("open", false)) == want:
		return
	if want:
		_open_door(id, false, opened_by_hand(id) if th.kind == "hand_door" else 0)
	else:
		_close_door(id)


func is_gate_open(d: Dictionary) -> bool:
	var auth := GameAuthority.instance
	return auth != null and auth.keys != null and auth.keys.gate_open(list_id(d))


## Which way a hand door swung open (+1 / -1), 0 = shut. Kept in world_state.dungeon_opened (saved, sent to everyone).
func opened_by_hand(id: int) -> int:
	var auth := GameAuthority.instance
	return int(auth.world_state.get("dungeon_opened", {}).get(str(id), 0)) if auth else 0


## What E does on thing `id` (for the aim line): {} or {name, use}.
func use_info(id: int) -> Dictionary:
	var th: Dictionary = things.get(id, {})
	if th.is_empty():
		return {}
	if MineTraps.kind_of(th.prop) != "":
		return mine.use_info(id)
	match String(th.kind):
		"hand_door":
			return {} if opened_by_hand(id) != 0 else {name = "Round door · E to open", use = id}
		"lever":
			return {name = "Old lever · E to pull" if not is_gate_open(th.d) else "Old lever (pulled)", use = id}
		"door":  # F848 (owner, Nov 25): a key door (Hald's Bronze door) opens with E while you carry its key
			var keys := DungeonKeys.keys_of(list_id(th.d))
			if keys.is_empty() or is_door_open(th.d):
				return {}
			var names: Array = keys.map(func(k): return String(DungeonKeys.KEYS[k].name))
			return {name = "Locked door (the %s) · E to unlock" % " and the ".join(names), use = id}
	return {}


## Our E on thing `id` (a hand door or a lever): ask the host.
func ask_use(id: int) -> void:
	var auth := GameAuthority.instance
	var th: Dictionary = things.get(id, {})
	if auth == null or th.is_empty():
		return
	if th.kind == "lever":
		auth.keys.ask_pull_lever(list_id(th.d))  # (DungeonKeys: request -> host -> everyone; it says what happened)
		return
	if th.kind == "door":
		auth.keys.ask_unlock(list_id(th.d))  # (F848: nothing called it, so the Bronze door never opened, key or not)
		return
	if auth.is_host():
		request_use(auth.local_peer_id(), id)
	else:
		_rpc_use.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _rpc_use(id: int) -> void:
	var auth := GameAuthority.instance
	if auth and auth.is_host():
		request_use(multiplayer.get_remote_sender_id(), id)


## Host: a player opens a hand door. It swings toward them (away from the side they push from, so it never hits them:
## it swings open to their side of the wall, past them, on its hinge).
func request_use(peer_id: int, id: int) -> void:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	var th: Dictionary = things.get(id, {})
	if mine.request_use(peer_id, id):
		return
	if ps == null or th.is_empty() or th.kind != "hand_door" or opened_by_hand(id) != 0:
		return
	var t: Transform3D = th.xform
	var at := ps.node.global_position
	if at.distance_to(t.origin) > USE_REACH + 1.5:
		return
	var way := 1 if (t.affine_inverse() * at).z < 0.0 else -1  # (+1: it swings to the door's back, where they stand)
	var all: Dictionary = auth.world_state.get("dungeon_opened", {}).duplicate()
	all[str(id)] = way
	auth.world_state["dungeon_opened"] = all
	_ev_hand_door.rpc(id, way)


@rpc("authority", "call_local", "reliable")
func _ev_hand_door(id: int, way: int) -> void:
	var auth := GameAuthority.instance
	if auth and not auth.is_host():
		var all: Dictionary = auth.world_state.get("dungeon_opened", {}).duplicate()
		all[str(id)] = way
		auth.world_state["dungeon_opened"] = all
	if things.has(id):
		_open_door(id, true, way)


## Everyone: the way out's gate opened (the lever was pulled) or shut again (the dungeon refilled).
func _on_gate_changed(dungeon_id: String, open: bool) -> void:
	for id in things:
		var th: Dictionary = things[id]
		if list_id(th.d) != dungeon_id:
			continue
		if th.kind == "gate":
			if open:
				_open_door(id, true, -1)  # (it swings toward the way out, where the one who pulled the lever stands)
			else:
				_close_door(id)


# ================================================================== the portcullis (Hald's Honour Chapel, F843)

const PORTCULLIS_LIFT := 1.15  ## how far up its gate hangs, in the model's metres (builds/dungeon_portcullis.py GATE_LIFT)
const PORTCULLIS_IN := 2.5     ## how far into its room a dwarf walks before it drops behind them


func is_portcullis_shut(id: int) -> bool:
	var auth := GameAuthority.instance
	return auth != null and bool(auth.world_state.get("dungeon_shut", {}).get(str(id), false))


## Host: a portcullis drops while a living dwarf stands PORTCULLIS_IN into its room and the room's creatures live; it
## lifts when they are all dead, or when no living dwarf is left in the room (so nobody is locked out for good).
func _check_portcullises(auth: GameAuthority) -> void:
	for id in things:
		var th: Dictionary = things[id]
		if th.kind != "portcullis":
			continue
		var room := String(th.prop.get("room", ""))
		var alive := bool(_room_alive.get(String(th.d.id) + "/" + room, false))
		var deep: Array = []
		var inside := false
		for pid in auth.players:
			var ps = auth.players[pid]
			if ps.node == null or (ps.vitals and ps.vitals.is_dead()):
				continue
			if in_room(th.d, room, ps.node.global_position, 0.0):
				inside = true
			if in_room(th.d, room, ps.node.global_position, PORTCULLIS_IN):
				deep.append(pid)
		var shut := is_portcullis_shut(id)
		if not shut and alive and not deep.is_empty():
			_set_portcullis(auth, id, true)
			for pid in deep:
				auth.tell(pid, "A rusted gate slams down behind you!")
		elif shut and (not alive or not inside):
			_set_portcullis(auth, id, false)


## Is world point `p` inside room `room` of dungeon `d`, at least `margin` m in from its walls (and between its floor
## and ceiling)?
static func in_room(d: Dictionary, room: String, p: Vector3, margin: float) -> bool:
	var q := DungeonMap.to_local(d, p)
	for s in d.map.spaces:
		if String(s[0]) == room:
			return q.x > float(s[1]) + margin and q.x < float(s[3]) - margin and q.z > float(s[2]) + margin \
				and q.z < float(s[4]) - margin and q.y > float(s[5]) - 0.5 and q.y < float(s[5]) + float(s[6])
	return false


func _set_portcullis(auth: GameAuthority, id: int, shut: bool) -> void:
	var all: Dictionary = auth.world_state.get("dungeon_shut", {}).duplicate()
	if shut:
		all[str(id)] = true
	else:
		all.erase(str(id))
	auth.world_state["dungeon_shut"] = all
	_ev_portcullis.rpc(id, shut)


@rpc("authority", "call_local", "reliable")
func _ev_portcullis(id: int, shut: bool) -> void:
	var auth := GameAuthority.instance
	if auth and not auth.is_host():
		var all: Dictionary = auth.world_state.get("dungeon_shut", {}).duplicate()
		if shut:
			all[str(id)] = true
		else:
			all.erase(str(id))
		auth.world_state["dungeon_shut"] = all
	if things.has(id):
		_move_portcullis(id, not shut, true)


## Everyone: the gate hangs up in the wall (`raised`: its teeth show under the arch, the clue) or stands on the floor
## and blocks the way. `slow`: it slams down fast with a crash, or grinds back up.
func _move_portcullis(id: int, raised: bool, slow: bool) -> void:
	var th: Dictionary = things[id]
	th.open = raised
	for c in (th.node as Node).get_children():
		if c is CollisionShape3D and c.has_meta("gate"):
			(c as CollisionShape3D).disabled = raised
	var gate := (th.inst as Node3D).find_child("gate", true, false) as Node3D
	if gate == null:
		return
	if not th.has("gate_rest"):
		th.gate_rest = gate.position
	var to: Vector3 = th.gate_rest + Vector3.UP * (PORTCULLIS_LIFT if raised else 0.0)
	if th.has("tween") and is_instance_valid(th.tween):
		(th.tween as Tween).kill()
	if not slow or not gate.is_inside_tree():
		gate.position = to
		return
	var at: Vector3 = (th.xform as Transform3D).origin + Vector3.UP
	var tw := create_tween()
	th.tween = tw
	if raised:
		Sfx.play("chop", at, 0.0, 0.4)
		tw.tween_property(gate, "position", to, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		tw.tween_property(gate, "position", to, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(Sfx.play.bind("hit_heavy", at, 3.0, 0.7))


const LEVER_PIVOT := Vector3(0.0, 1.05, 0.13)  ## where the lever's handle turns (tools/asset_forge/builds/dungeon_rootwood.py)


## Everyone: the lever's handle swings down (pulled) or back up.
func _pull_lever(id: int, down: bool) -> void:
	var th: Dictionary = things[id]
	var handle := (th.inst as Node).find_child("handle", true, false) as Node3D
	if handle == null:
		return
	if not th.has("handle_rest"):
		th.handle_rest = handle.transform
	var rest: Transform3D = th.handle_rest
	var to := deg_to_rad(110.0) if down else 0.0
	var turn := func(a: float) -> void:
		if is_instance_valid(handle):
			var r := Basis(Vector3.RIGHT, a)
			handle.transform = Transform3D(r * rest.basis, LEVER_PIVOT + r * (rest.origin - LEVER_PIVOT))
	Sfx.play("chop", (th.xform as Transform3D) * LEVER_PIVOT, -2.0, 0.5)
	create_tween().tween_method(turn, deg_to_rad(110.0) - to, to, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Everyone: a dungeon door opened or shut.
func _on_door_changed(dungeon_id: String, open: bool) -> void:
	for id in things:
		var th: Dictionary = things[id]
		if th.kind == "door" and list_id(th.d) == dungeon_id:
			if open:
				_open_door(id, true)
			else:
				_close_door(id)


## A round door (or the gate) swings open on its left edge (its body goes; `slow` = with a creak, else at once).
## `way`: +1 swings it to its back, -1 to its front, 0 = the loot door's usual way (to its front).
func _open_door(id: int, slow: bool, way := 0) -> void:
	var th: Dictionary = things[id]
	if th.get("open", false):
		return
	th.open = true
	for c in (th.node as Node).get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	var t: Transform3D = th.xform
	var hinge := t * Vector3(-0.74, 0, 0)  # (its left edge: the round door is 0.78 m round; it was 0.46, inside the door)
	var shut := t
	var angle := deg_to_rad(100.0) * (float(way) if way != 0 else -1.0)
	var swing := func(f: float) -> void:
		var r := Basis(Vector3.UP, angle * f)
		(th.inst as Node3D).transform = Transform3D(r * shut.basis, hinge + r * (shut.origin - hinge))
	if slow:
		Sfx.play("chop", hinge + Vector3.UP, 0.0, 0.4)
		create_tween().tween_method(swing, 0.0, 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		swing.call(1.0)


func _close_door(id: int) -> void:
	var th: Dictionary = things[id]
	if not th.get("open", false):
		return
	th.open = false
	(th.inst as Node3D).transform = th.xform
	for c in (th.node as Node).get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = false


## The deadly drop `p` has fallen into ("chasm", "spike_pit"; "" = none): down among the spikes of a space whose
## floor is below the dungeon's floor.
static func deadly_space(d: Dictionary, p: Vector3) -> String:
	if not DungeonMap.near_box(d, p, 2.0):
		return ""
	var q := DungeonMap.to_local(d, p)
	var only: Array = d.map.get("deadly", [])  # (Pell's: its whole lower level is under 0, only the spike pit kills)
	for s in d.map.spaces:
		# (F846, Nov 25: no bottom to the box killed you in Hald's tomb door, 5 m under the pit: only near its floor)
		if float(s[5]) < 0.0 and (only.is_empty() or String(s[0]) in only) and q.x > float(s[1]) - 0.5 and q.x < float(s[3]) + 0.5 and q.z > float(s[2]) - 0.5 				and q.z < float(s[4]) + 0.5 and q.y < float(s[5]) + 1.2 and q.y > float(s[5]) - 2.0:
			return String(s[0])
	return ""


# ================================================================== the recipe stand's scroll

## Everyone: the recipe stand shows its scroll while the page is in it. Owner, Nov 20 (3rd play): taking it, the
## scroll rolls up (its two rolls meet in the middle), shrinks with a little glow and is gone. Loading a stand that is
## already empty just hides it.
static func show_scroll(body: Node3D, inv: Inventory) -> void:
	var scroll := body.find_child("Scroll", true, false) as Node3D
	if scroll == null:
		return
	var has := false
	for sl in inv.slots:
		if not sl.is_empty() and Items.kind(String(sl.id)) == "page":
			has = true
	if has:
		if not body.has_meta("scroll_rest"):
			body.set_meta("scroll_rest", scroll.transform)
		scroll.transform = body.get_meta("scroll_rest")
		scroll.visible = true
		body.set_meta("scroll_seen", true)
		return
	if not scroll.visible:
		return
	if not body.get_meta("scroll_seen", false) or not scroll.is_inside_tree():
		scroll.visible = false
		return
	body.set_meta("scroll_seen", false)
	var rest: Transform3D = scroll.transform
	var tw := scroll.create_tween()
	tw.tween_method(func(f: float) -> void:  # rolling up: narrower and narrower, lifting a little off the stand
		scroll.transform = Transform3D(rest.basis.scaled_local(Vector3(1.0 - 0.85 * f, 1.0 + 0.6 * f, 1.0)), rest.origin + Vector3.UP * 0.04 * f),
		0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		Fx.burst(scroll.get_parent(), scroll.global_position, Color(1.0, 0.85, 0.45), 10, 1.2))
	tw.tween_method(func(f: float) -> void:  # then the little roll shrinks away
		scroll.transform = Transform3D(rest.basis.scaled_local(Vector3(0.15, 1.6, 1.0) * (1.0 - f)), rest.origin + Vector3.UP * (0.04 + 0.12 * f)),
		0.0, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		scroll.visible = false
		scroll.transform = rest)


# ================================================================== chests (host, once, when the world is made)

## Loot for each kind of chest in the plan (decisions: the loot room holds good Zone 1 things + a chance of a rare
## find; the rare finds list comes with the loot tables). [item, min, max, chance]
const LOOT := {
	"random": [["gold_coin", 3, 8, 1.0], ["rope", 1, 3, 0.5], ["bandage", 1, 3, 0.5], ["copper_ingot", 2, 4, 0.35],
		["bolt_stone", 4, 10, 0.4], ["coal", 3, 6, 0.4], ["crystal_torch", 1, 2, 0.25]],
	"vault": [["gold_coin", 12, 20, 1.0], ["copper_ingot", 5, 8, 1.0], ["silver_ore", 3, 5, 0.6], ["crystal_white", 1, 1, 0.3]],
	"buried": [["gold_coin", 8, 14, 1.0], ["bolt_metal", 6, 10, 0.8], ["bandage", 2, 4, 0.6]],
	"big": [["gold_coin", 25, 40, 1.0], ["copper_ingot", 8, 12, 1.0], ["bolt_metal", 10, 16, 1.0], ["bandage", 4, 6, 1.0],
		["leather", 3, 5, 0.6], ["crystal_white", 1, 2, 0.35], ["blueprint_page", 1, 1, 0.2]],
}
const RANDOM_CHEST_CHANCE := 0.65  ## a "random chest" is there in about 2 of 3 worlds


## Host, new world: every dungeon's chests become real chests with loot (saved and sent like any chest), and the loot
## room's recipe stand holds its dungeon's page (always the same recipe: decisions round 4).
## F844 step 5 (docs/decisions/2026-11-24-zone1-metal-and-loot.md): what a dungeon's big chest always holds as well,
## by DungeonList id. Mossgate Hold, the first dungeon, gives the Bronze Pickaxe page.
const BIG_CHEST_EXTRA := {"mossgate_hold": {"page_pickaxe_bronze": 1}}

static func add_chests(auth: GameAuthority, p_maker: CaveMaker) -> void:
	for d in p_maker.dungeons:
		var plan := load_plan(String(d.id))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([p_maker.seed, String(d.id), "chests"])
		for c in plan.get("chests", []):
			if not c.get("always", false) and rng.randf() > RANDOM_CHEST_CHANCE:
				continue
			var t := _xform(d, c.pos, float(c.yaw) + 180.0, 1.0, 0.0)  # (box fronts face -Z, the models +Z)
			var id: int = auth.storage.create_box(String(c.kind), t.origin, t.basis.get_euler().y)
			for row in LOOT.get(String(c.get("loot", "random")), LOOT.random):
				if rng.randf() < float(row[3]) and Items.exists(String(row[0])):
					auth.storage.put(id, String(row[0]), rng.randi_range(int(row[1]), int(row[2])))
			if String(c.get("loot", "")) == "big":  # the last chest always holds 1 of the dungeon's gems (gems.md)
				auth.storage.put(id, Gems.item_id(Gems.end_chest_gem(String(d.id), rng.randf(), rng.randf())), 1)
				for item in BIG_CHEST_EXTRA.get(list_id(d), {}):  # and its fixed extras (F844: Mossgate's Bronze Pickaxe page)
					if Items.exists(item):
						auth.storage.put(id, item, int(BIG_CHEST_EXTRA[list_id(d)][item]))
		var stand: Dictionary = plan.get("recipe_stand", {})
		if not stand.is_empty() and Items.exists(String(stand.page)):
			var t := _xform(d, stand.pos, float(stand.yaw) + 180.0, 1.0, 0.0)
			var sid: int = auth.storage.create_box(String(stand.get("kind", "recipe_stand")), t.origin, t.basis.get_euler().y)
			auth.storage.put(sid, String(stand.page), 1)
		print("DUNGEON_CHESTS %s placed" % d.id)
