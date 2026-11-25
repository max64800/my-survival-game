class_name Monsters
## Monster data for Mossy Hollows and the Fungal Jungle (combat doc 5.2, 5.3, 6, 7).
## Owner, Nov 19: only these five creatures are in the caves (no bosses, no raids, no other creatures).
## Nov 20: plus the three skeleton miners of the dungeons (Tunnel Rat, Lost Miner, the Foreman: dungeon_only).
## Each attack: tell = seconds of warning before it lands, reach in meters,
## parry: "any" (weapon or shield), "shield" (crushing: only a shield parry works).
## buildup = {poison/burn/chill: amount} fills the target's Ailments meter (combat doc 2.6).
## cloud = a spore cloud left when the attack lands: at "self", "target" or "between" them,
## radius m, time s, rate = poison buildup per second inside, dps = damage per second inside.

static var LIST := {
	# ---- The first three, designed with the owner (docs/design/monsters-first-three.md).
	# shell_hide: when its health drops to each of `at` (fractions) it hides in its shell for `seconds`, taking `cut`
	# less damage (owner, Nov 18: once at half health, once at 10%, 10 s each: you have to wait it out, no stun-lock).
	# swoops: a flyer that cruises high, dives to bite, then climbs away (retreat m, recover s).
	# roosts: starts asleep, hanging from a cave ceiling.
	# climbs (owner, Nov 20, docs/decisions/2026-11-20-creature-climbing.md): "all" = walls and ceilings, "walls" = walls
	# only (out of holes, up ledges); none = never. falls_dazed: knocked off the rock by a hit, it lands on its back,
	# dazed. wall_runner: chasing, it runs up any wall in its way. ambush: over you on the ceiling it hisses, then drops.
	# soft_back: hits from behind do `back_mult` damage. straight_charge: a charge doesn't steer.
	"rock_snail": {name = "Rock Snail", ragdoll = {stay = ["soft_foot"], hop = 0.3, roll = "side", spin = 3.2, narrow = 0.5}, size = 1.0, hp = 110, armor = 0, stun = 50, slash = 0.75, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 0.6, run = 0.6, pack = [1, 2], xp = 14, leader = "Old Shellback", leader_chance = 0.15,  # (run = walk: it never runs, owner Nov 17)
		color = Color(0.48, 0.44, 0.38), shape = "rock_snail", neutral = true, climbs = "all", falls_dazed = true, turns_in_place = true, shell_hide = {at = [0.5, 0.1], seconds = 10.0, cut = 0.9},
		attacks = [{name = "Lunging Bite", tell = 0.9, damage = 14, type = "pierce", reach = 1.7, parry = "any"},
			# Spit (owner, Nov 17): short range (2-3 m), a shield stops it completely; he rears up, snaps, a gob flies.
			{name = "Spit", tell = 0.8, damage = 12, type = "blunt", reach = 3.0, min_reach = 1.6, parry = "any", spit = true, shield_stops = true, buildup = {poison = 100}}],
		drops = [["snail_meat", 1, 1.0], ["snail_meat", 1, 0.5], ["shell_piece", 2, 0.8]]},
	# Cave bats (owner, Nov 18): packs of 5-10; hit one and the whole pack wakes and swoops at you, flies back, swoops
	# again; easy (one heavy or two light sword hits each), they drop the wing leather that tans into leather armour.
	"cave_bat": {name = "Cave Bat", turns_in_place = true, turn_speed = 3.2, weaves = true, ragdoll = {hop = 0.4, spin = 6.0}, statue_hits = 1, size = 1.0, hp = 20, armor = 0, stun = 35, slash = 1.0, blunt = 1.0, pierce = 1.25,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 3.0, run = 6.5, pack = [5, 10], xp = 4, leader = "Bat Matriarch", leader_chance = 0.15,
		color = Color(0.3, 0.26, 0.28), shape = "cave_bat", flap_sound = "bat_flap", flies = true, swoops = true, roosts = true, sleeps = true,
		hit_and_run = true, retreat = 7.0, recover = 1.6,
		# F419 (owner, Nov 19): carry a light within 25 m of the roost and they wake; they keep attacking until you
		# leave their cave (they don't give up after 10 s like the others).
		# F428 (owner, Nov 20: "make the bats' aggro range smaller"): 25 m → 12 m.
		wake_light = 12.0, stays_in_cave = true,
		# F460 (owner, Nov 20): it circles you, then dives straight THROUGH you at twice its speed (leaving a trail) and
		# climbs away on the other side; no stopping. The tell is worked out from how far it has to fly (Monster._start_dive).
		attacks = [{name = "Dive Through", warn_sound = "bat_screech", tell = 0.6, damage = 6, type = "pierce", reach = 1.2, parry = "any", dive = true}],
		drops = [["wing_leather", 1, 1.0], ["wing_leather", 1, 0.3], ["bat_fang", 1, 0.4], ["bat_meat", 1, 0.8]]},
	# statue_hits: pickaxe hits to break its stone statue (default 2; owner, Nov 21, F586: bats 1, every other creature 2,
	# bosses 5).
	# ragdoll: on death it goes limp and falls apart into physics pieces (Ragdoll; the beetle first, owner Nov 18).
	"rock_beetle": {name = "Rock Beetle", turns_in_place = true, turn_speed = 2.6, ragdoll = true, size = 0.9, hp = 100, armor = 0, stun = 45, slash = 0.75, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 1.8, run = 4.5, pack = [1, 2], xp = 15, leader = "Rock Beetle Brute", leader_chance = 0.2,
		color = Color(0.42, 0.39, 0.35), shape = "rock_beetle", soft_back = 2.0, straight_charge = true, recover = 1.8, climbs = "walls",
		attacks = [{name = "Mandible Snap", warn_sound = "beetle_hiss", tell = 0.7, damage = 10, type = "pierce", reach = 1.7, parry = "any"},
			{name = "Charge", warn_sound = "beetle_rumble", tell = 1.1, damage = 18, type = "blunt", reach = 9.0, parry = "shield", lunge = true}],
		drops = [["bug_meat", 2, 1.0], ["glow_gland", 1, 0.6]]},
	"great_rock_beetle": {name = "Great Rock Beetle", elite = true, turns_in_place = true, turn_speed = 1.8, ragdoll = true, statue_hits = 2, size = 1.5, hp = 240, armor = 40, stun = 144, slash = 0.75, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.25, walk = 2.0, run = 5.0, pack = [1, 1], xp = 45, leader = "Great Rock Beetle Matron", leader_chance = 0.1,
		color = Color(0.33, 0.31, 0.29), shape = "rock_beetle", soft_back = 2.0, straight_charge = true, recover = 2.0,
		attacks = [{name = "Horn Gore", warn_sound = "beetle_hiss", tell = 0.9, damage = 22, type = "pierce", reach = 2.4, parry = "any"},
			{name = "Charge", warn_sound = "beetle_rumble", tell = 1.3, damage = 30, type = "blunt", reach = 12.0, parry = "shield", knockdown = true, lunge = true}],
		drops = [["bug_meat", 4, 1.0], ["glow_gland", 2, 0.9], ["beetle_meat", 2, 1.0], ["chitin_plate", 1, 0.6], ["chitin_plate", 1, 0.3]]},
	# Cave Spider (owner, Nov 19): a Zone 1 pest, Claude 1's model (cave_spider_v0..3.glb), in as it is for the owner to
	# test. Small groups; it scuttles in, bites, and pounces from a few metres (pounce = a leap during the lunge),
	# then skitters back (hit_and_run). Planned later: webs. One heavy hit or two light ones kill it.
	"cave_spider": {name = "Cave Spider", turns_in_place = true, turn_speed = 4.0, ragdoll = {hop = 0.5, spin = 2.0}, statue_hits = 2, size = 1.0, hp = 30, armor = 0, stun = 13, slash = 1.0, blunt = 1.0, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 2.2, run = 5.5, pack = [3, 5], xp = 6, leader = "Spider Broodmother", leader_chance = 0.15,
		color = Color(0.25, 0.22, 0.2), shape = "cave_spider", climbs = "all", wall_runner = true, ambush = true, hit_and_run = true, retreat = 4.0, recover = 1.2,
		attacks = [{name = "Bite", warn_sound = "beetle_hiss", tell = 0.5, damage = 7, type = "pierce", reach = 1.5, parry = "any", buildup = {poison = 34}},
			{name = "Pounce", warn_sound = "beetle_hiss", tell = 0.8, damage = 11, type = "pierce", reach = 5.0, parry = "any", lunge = true, pounce = true, buildup = {poison = 34}}],
		drops = [["bug_meat", 1, 1.0], ["bug_meat", 1, 0.4], ["spider_silk", 1, 0.7], ["spider_silk", 1, 0.35], ["venom_sac", 1, 0.3]]},
	# ---- The skeleton miners of Lampwick Drift and Old Pell's Diggings (dungeons 2 and 3; owner OK'd the models Nov 20).
	# They move by a skeleton (CreatureRig), not by named parts. rises: they lie scattered on the floor and get up when
	# someone comes within rise_near m in their room, is seen, or hits them (F462). anim: the move each attack plays (its
	# blow lands when the attack does). height: their body's height (the models are already their real size: size 1).
	# dungeon_only: they only live in dungeons (placed by the plan's "creatures" list, never in cave packs).
	# no_variant: no fiery/icy crystal ones (crystals can't follow the bones; the Lost Miner is icy already).
	# No drops yet (only the statue's stone): asked the owner what the dead miners' bones should give.
	# F467: the Tunnel Rat is a small fast pest in groups, easy to kill, soft hits.
	"tunnel_rat": {name = "Bone Rot", dungeon_only = true, rises = true, rise_near = 11.0, sleeps = true, no_variant = true, ragdoll = false, statue_hits = 2,
		size = 1.0, height = 1.0, hp = 60, armor = 0, stun = 12, slash = 1.0, blunt = 1.25, pierce = 0.75,
		fire = 0.0, frost = 0.0, poison = 1.0, walk = 2.0, run = 5.0, pack = [3, 5], xp = 5,
		color = Color(0.62, 0.56, 0.45), shape = "tunnel_rat", recover = 0.8,
		# F606: only the overhand chop (readable wind-up); the stab had no warn_sound and was too fast.
		attacks = [{name = "Shovel Chop", anim = "1H_Melee_Attack_Chop", warn_sound = "beetle_hiss", tell = 0.55, damage = 6, type = "slash", reach = 1.5, parry = "any"}],
		drops = []},
	# F466/F467: the Lost Miner is slow and tough, and its pick is ice cold (chill buildup: 3 hits freeze you).
	"lost_miner": {name = "Hollow Miner", dungeon_only = true, rises = true, rise_near = 11.0, sleeps = true, no_variant = true, ragdoll = false, statue_hits = 2,
		size = 1.0, height = 1.45, hp = 110, armor = 0, stun = 50, slash = 1.0, blunt = 1.25, pierce = 0.75,
		fire = -0.25, frost = 0.75, poison = 1.0, walk = 1.0, run = 2.6, pack = [1, 3], xp = 14,
		no_push = true,  # F609: stops at 1.5 m in chase so it can't body-push the player
		color = Color(0.7, 0.82, 0.78), shape = "lost_miner", recover = 1.2,
		# F593: picks shortened so running away gets you out. F605: only the Leaping Chop now (owner Nov 22:
		# "should only do lunge"); Frost Pick and Pick Jab removed. At ≤2 m the miner circles and waits for space.
		# Its leap rushes at 2.6 m/s (was 3.4): the dwarf walks 3 m/s now (was 4), and walking off must still get you out.
		attacks = [{name = "Leaping Chop", anim = "1H_Melee_Attack_Chop", warn_sound = "beetle_hiss", tell = 0.9, damage = 14, type = "pierce", reach = 3.0, parry = "any", lunge = true, small_lunge = true, lunge_speed = 2.6, rest = 4.0, quiet_after = 3.5, buildup = {chill = 34}}],
		drops = []},
	# The ghosts of the medium dungeons #5-#8 (Claude, Nov 22, 2026; owner: the dwarf's skeleton and his mace moves,
	# "three different attacks, and the boss can do all four"). A ghost is a dwarf wearing a ghost body (Ghost, GhostRig):
	# it floats, swings a ghostly mace with one of the dwarf's own mace moves (anim = DwarfRig's "mace_1".."mace_4", slowed
	# down so you see it coming), and after every quarter of its health it fades into mist and comes back a few metres
	# away, rushing at you (ghost = true: MonsterManager.ghost_fade). Weapons pass half through it (low slash/pierce).
	"ghost_a": {name = "Drifting Shade", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0,
		size = 1.0, height = 1.5, hp = 150, armor = 0, stun = 60, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.2, run = 3.0, pack = [1, 2], xp = 18,
		color = Color(0.5, 0.95, 0.8), shape = "ghost", recover = 1.2,
		attacks = [{name = "Shade Swing", anim = "mace_1", warn_sound = "beetle_hiss", tell = 0.85, damage = 16, type = "blunt", reach = 2.2, parry = "any", rest = 2.5}],
		drops = []},
	"ghost_b": {name = "Wrathful Shade", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0,
		size = 1.0, height = 1.6, hp = 140, armor = 0, stun = 55, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.4, run = 3.4, pack = [1, 2], xp = 20,
		color = Color(0.55, 0.75, 1.0), shape = "ghost", recover = 1.4,
		# the angry one: it rocks back, mace high, and swoops in with a slanting blow (a short lunge; owner, Nov 22: mace move 2 alone was "just spinning")
		attacks = [{name = "Swooping Blow", anim = "SliceDiag", warn_sound = "beetle_hiss", tell = 0.85, damage = 18, type = "blunt", reach = 3.0, parry = "any", lunge = true, small_lunge = true, lunge_speed = 3.6, rest = 3.5}],
		drops = []},
	"ghost_c": {name = "Bearded Shade", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0,
		size = 1.05, height = 1.55, hp = 170, armor = 0, stun = 70, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.1, run = 2.8, pack = [1, 1], xp = 22,
		color = Color(0.6, 0.95, 0.7), shape = "ghost", recover = 1.6,
		attacks = [{name = "Old Grudge", anim = "Chop", warn_sound = "beetle_rumble", tell = 1.05, damage = 20, type = "blunt", reach = 2.3, parry = "any", rest = 3.0}],
		drops = []},
	# The ghosts' lord: the bearded shade, bigger and paler, with all four mace moves in one combo (the last one knocks you
	# down), and the big smash alone from further away.
	"ghost_lord": {name = "The Grey Warden", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0, boss = true,
		size = 1.35, height = 2.0, hp = 520, armor = 30, stun = 320, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.3, run = 3.2, pack = [1, 1], xp = 90,
		color = Color(0.78, 0.9, 1.0), shape = "ghost", recover = 1.8,
		attacks = [{name = "Warden's Combo", anim = "mace_1", warn_sound = "beetle_rumble", tell = 0.9, damage = 16, type = "blunt", reach = 2.6, parry = "any", rest = 6.0,
				follow = {anim = "mace_2", tell = 0.6, damage = 16, warn_sound = null, follow = {anim = "mace_3", tell = 0.6, damage = 18,
					follow = {anim = "mace_4", tell = 0.75, damage = 26, knockdown = true}}}},
			{name = "Grave Smash", anim = "mace_4", warn_sound = "beetle_rumble", tell = 1.0, damage = 24, type = "blunt", reach = 3.4, parry = "any", lunge = true, small_lunge = true, lunge_speed = 3.8, rest = 5.0}],
		drops = []},
	# Tomb of Hald Ironbrow (owner, Nov 24, F843). The mini boss: Hald's oath-brother, a big Bearded Shade who still
	# guards the Honour Chapel. He blocks every hit from the front (front_shield, like the Prop Warden): walk round him.
	# He holds the Bronze Key (DungeonKeys.KEYS.key_bronze) that opens the Bronze door behind Hald's tomb.
	"shield_brother": {name = "The Shield-Brother", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0,
		# F850 (owner, Nov 25: "he never turns his back"): he turns slowly (turns_in_place: step round him), his shield
		# drops for a moment after each swing (GhostRig.shield_open: hit him then), and he charges behind his shield
		# when you keep away (a dodge-able run; he stands dazed after it, his back open).
		front_shield = true, no_push = true, key = "key_bronze", turns_in_place = true, turn_speed = 1.7,
		size = 1.25, height = 1.9, hp = 280, armor = 20, stun = 200, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.1, run = 2.9, pack = [1, 1], xp = 50,
		color = Color(0.62, 0.92, 0.75), shape = "ghost", recover = 1.7,
		attacks = [{name = "Shield Charge", anim = "charge", warn_sound = "beetle_rumble", tell = 1.1, damage = 18, type = "blunt", reach = 8.0, min_reach = 3.5, rest = 8.0, parry = "shield", knockdown = true, lunge = true, straight = true, lunge_reach = 3.0},
			{name = "Oath Chop", anim = "Chop", warn_sound = "beetle_rumble", tell = 1.0, damage = 20, type = "blunt", reach = 2.4, parry = "any", rest = 3.5},
			{name = "Grave Smash", anim = "mace_4", warn_sound = "beetle_rumble", tell = 1.1, damage = 22, type = "blunt", reach = 3.2, parry = "any", lunge = true, small_lunge = true, lunge_speed = 3.4, rest = 7.0}],
		drops = []},
	# Hald's two tomb guards (F849, owner: "2 easy ghost minions fight with him"): small and weak, one slow swing.
	"hald_shade": {name = "Tomb Shade", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 9.0,
		size = 0.9, height = 1.4, hp = 70, armor = 0, stun = 40, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.1, run = 2.6, pack = [1, 1], xp = 8,
		color = Color(0.55, 0.85, 0.95), shape = "ghost", recover = 1.6,
		attacks = [{name = "Shade Swing", anim = "mace_1", warn_sound = "beetle_hiss", tell = 1.0, damage = 9, type = "blunt", reach = 2.1, parry = "any", rest = 3.5}],
		drops = []},
	# The end boss: Hald Ironbrow himself (owner: "final boss is a ghost, obviously"): the ghosts' lord body and moves
	# (all four mace moves in one combo, mist every quarter of his health), rising from his tomb. F849 (owner, Nov 25:
	# "too easy"): he runs you down (faster than you walk), swings more often, and two Tomb Shades rise with him.
	"hald_ironbrow": {name = "Hald Ironbrow", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0, boss = true,
		no_push = true, size = 1.4, height = 2.1, hp = 560, armor = 30, stun = 320, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.6, run = 4.3, pack = [1, 1], xp = 100,
		color = Color(0.8, 0.88, 1.0), shape = "ghost", recover = 1.8,
		attacks = [{name = "Ironbrow's Combo", anim = "mace_1", warn_sound = "beetle_rumble", tell = 0.9, damage = 16, type = "blunt", reach = 2.6, parry = "any", rest = 4.0, chain = true,
				follow = {anim = "mace_2", tell = 0.6, damage = 16, warn_sound = null, follow = {anim = "mace_3", tell = 0.6, damage = 18,
					follow = {anim = "mace_4", tell = 0.75, damage = 26, knockdown = true}}}},
			{name = "Grave Smash", anim = "mace_4", warn_sound = "beetle_rumble", tell = 1.0, damage = 24, type = "blunt", reach = 3.4, parry = "any", lunge = true, small_lunge = true, lunge_speed = 4.6, rest = 3.5}],
		drops = []},
	# The Quiet Barrows (F906, owner Nov 25: "ghosts and spiders, the boss a rune ghost"). The Barrow Warden: a big
	# Bearded Shade who leads the Keepers' Barrow (not a boss: two keepers rise with him).
	"barrow_warden": {name = "The Barrow Warden", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 8.0,
		size = 1.25, height = 1.9, hp = 240, armor = 15, stun = 160, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.2, run = 3.2, pack = [1, 1], xp = 40,
		color = Color(0.62, 0.9, 0.8), shape = "ghost", recover = 1.7,
		attacks = [{name = "Warden's Chop", anim = "Chop", warn_sound = "beetle_rumble", tell = 1.0, damage = 18, type = "blunt", reach = 2.4, parry = "any", rest = 3.5},
			{name = "Grave Smash", anim = "mace_4", warn_sound = "beetle_rumble", tell = 1.1, damage = 20, type = "blunt", reach = 3.2, parry = "any", lunge = true, small_lunge = true, lunge_speed = 3.4, rest = 6.0}],
		drops = []},
	# The end boss: the Barrow Keeper, a rune ghost (owner). He holds the Barrow Key (DungeonKeys.KEYS.key_barrow) to
	# the King's Grave. Step 1: he fights with the ghost boss's mace moves; his glowing rune bolts come next (step 2).
	"barrow_keeper": {name = "The Barrow Keeper", dungeon_only = true, sleeps = true, no_variant = true, ragdoll = false, ghost = true, rise_near = 7.0, boss = true,
		no_push = true, key = "key_barrow", size = 1.45, height = 2.15, hp = 600, armor = 30, stun = 340, slash = 0.8, blunt = 0.9, pierce = 0.6,
		fire = 1.25, frost = 0.25, poison = 0.0, walk = 1.6, run = 4.3, pack = [1, 1], xp = 110,
		color = Color(0.7, 0.85, 1.0), shape = "ghost", recover = 1.8,
		attacks = [{name = "Keeper's Combo", anim = "mace_1", warn_sound = "beetle_rumble", tell = 0.9, damage = 16, type = "blunt", reach = 2.6, parry = "any", rest = 4.0, chain = true,
				follow = {anim = "mace_2", tell = 0.6, damage = 16, warn_sound = null, follow = {anim = "mace_3", tell = 0.6, damage = 18,
					follow = {anim = "mace_4", tell = 0.75, damage = 26, knockdown = true}}}},
			{name = "Grave Smash", anim = "mace_4", warn_sound = "beetle_rumble", tell = 1.0, damage = 24, type = "blunt", reach = 3.4, parry = "any", lunge = true, small_lunge = true, lunge_speed = 4.6, rest = 3.5}],
		drops = []},
	# The end boss with his Lost Miners (F467): only the spinning whirl (only a shield parries it, the last turn
	# knocks you down: step back out of it). F645 (owner, Nov 22): the Great Chop removed — it was readable and
	# parryable, breaking the "spin only" feel. Owner, Nov 20: 30% less health (420 -> 294); chat 16 (F532, the
	# owner's OK on the balance plan): 450 and armor 50, and his swings break the stone of fallen miners (like a beetle's charge).
	"foreman": {name = "The Pit Boss", dungeon_only = true, rises = true, rise_near = 10.0, sleeps = true, no_variant = true, ragdoll = false, statue_hits = 5, boss = true,
		smashes_statues = true, no_push = true, size = 1.0, height = 1.9, hp = 450, armor = 50, stun = 360, slash = 1.0, blunt = 1.25, pierce = 0.75,
		fire = 0.0, frost = 0.5, poison = 1.0, walk = 1.4, run = 3.6, pack = [1, 1], xp = 80,
		color = Color(0.55, 0.5, 0.44), shape = "foreman", recover = 1.6,
		# Owner, Nov 21 ("when he spins he should move towards the player: you have to dodge that"): the whirl now
		# goes on for 4 more turns (about 4 s in all), sliding after you at 2.6 m/s (you walk 3, run 5.2): every
		# turn hits (12), the last one hardest (20) and it knocks you down. Each follow turn gives 0.9 s to dodge.
		# Nov 22: tells raised from 0.5 to 0.9 s — was near-untelegraphed; now the glint shows 0.5 s before each blow.
		attacks = [{name = "Pick Whirl", anim = "2H_Melee_Attack_Spin", warn_sound = "beetle_rumble", tell = 0.97, damage = 12, type = "blunt", reach = 1.8, rest = 9.0, parry = "shield", knockdown = false, knock = 2.0,
			follow = {tell = 0.9, damage = 12, whirl_speed = 1.5, warn_sound = null, knock = 2.5, follow = {tell = 0.9, damage = 12, knock = 2.5,
				follow = {tell = 0.9, damage = 12, knock = 2.5, follow = {tell = 0.9, damage = 20, knockdown = true, knock = 3.5}}}}},
			# F679 (owner, Nov 22): other attacks besides spin; a heavy overhead chop for close-range pressure.
			{name = "Pick Crack", anim = "2H_Melee_Attack_Chop", warn_sound = "beetle_hiss", tell = 0.9, damage = 18, type = "blunt", reach = 2.2, parry = "any", knock = 2.5, rest = 5.0}],
		drops = []},
	# Mossprop Workings' boss (owner, Nov 21): a mossy skeleton miner with a felling axe and a plank shield on his left
	# arm (his own model, F468): hits from the front do a fifth (MonsterManager._shield_blocks) unless heavy or he is stunned.
	# F548 (owner, Nov 21: "a different boss, not the Pit Boss's moves"): he holds the shield up in front while he walks
	# at you (ShieldArm), swings the axe one-handed, and from 3.5-8 m he charges behind the shield in a straight line
	# (knocks you down; step aside and he runs past, then stands catching his breath: hit his back).
	# F547: 300 health (was 420: "way too much"), and the Plank Sweep comes at random against the chop (same reach).
	# Rally Slam (owner's picks, Nov 21): about every 25 s, if a fallen Lost Miner lies in stone in his room, he raises
	# his plank and slams it down (2 s: a deep rumble, the statues glow and shake), then up to 2 of them get up (never
	# more than 3 miners up at once). Hit him during the slam (his shield is up over his head) and it is called off;
	# a statue you mined away can't be raised. He doesn't smash his own miners' stone (the Pit Boss does; owner kept it, Nov 21).
	"prop_warden": {name = "The Prop Warden", dungeon_only = true, rises = true, rise_near = 10.0, sleeps = true, no_variant = true, ragdoll = false, statue_hits = 5, boss = true,
		front_shield = true, no_push = true, size = 1.0, height = 1.9, hp = 300,  # (no_push, F728: like the Pit Boss, F675)
		armor = 50, stun = 240, slash = 1.0, blunt = 1.25, pierce = 0.75,
		fire = 1.25, frost = 0.5, poison = 1.0, walk = 1.3, run = 3.3, pack = [1, 1], xp = 80,
		color = Color(0.5, 0.52, 0.4), shape = "foreman", recover = 1.6,
		attacks = [{name = "Axe Chop", anim = "1H_Melee_Attack_Chop", warn_sound = "beetle_rumble", tell = 0.9, damage = 22, type = "slash", reach = 2.3, rest = 5.0, parry = "any", knock = 2.5},
			{name = "Plank Sweep", anim = "2H_Melee_Attack_Spin", warn_sound = "beetle_rumble", tell = 0.97, damage = 16, type = "blunt", reach = 2.3, rest = 8.0, parry = "shield", knockdown = true, knock = 3.5},
			{name = "Shield Charge", anim = "Running_B", warn_sound = "beetle_rumble", tell = 1.2, damage = 20, type = "blunt", reach = 8.0, min_reach = 3.5, rest = 9.0, parry = "shield", knockdown = true, lunge = true, straight = true, lunge_reach = 3.0},
			{name = "Rally Slam", anim = "2H_Melee_Attack_Chop", warn_sound = "beetle_rumble", tell = 2.0, damage = 0, type = "blunt", reach = 14.0, rest = 25.0, parry = "any", raise_miners = 2, land_sound = "snail_slam"}],
		drops = []},
}


## {} for a creature the game no longer has (an old save's, Nov 19: the bosses and the
## other early creatures were taken out; only the five in LIST are left).
static func info(id: String) -> Dictionary:
	return LIST.get(id, {})


## Pack leader (doc 6.2) and the boost it gives its pack (doc 6.3). No crown: you spot it by its size (owner, Nov 19,
## F421: "take the crown off and make them a lot bigger").
const LEADER := {size = 1.8, hp = 2.5, damage = 1.3, stun = 1.5, armor = 25, xp = 3}  ## (armor 25: an elite, F532)
const PACK_BOOST := {damage = 0.20, speed = 0.15, stun = 0.25, decay = 2.0, radius = 15.0}

## Which monsters live where in each biome: big caverns / small rooms.
const SPAWNS := {
	# Owner's choice (Nov 14): only the first three for now. Snails + small beetles in Mossy Hollows,
	# bats roost in caverns everywhere, big beetles in the Fungal Jungle. (Old lists in git history.)
	# Bats aren't here: every cave has its own roost of them (MonsterManager._spawn_roost, owner Nov 19).
	# Cave spiders (owner, Nov 19): a Zone 1 pest, in big caverns and small rooms.
	"mossy": {big = ["rock_snail", "rock_snail", "rock_beetle", "cave_spider"], small = ["rock_snail", "rock_beetle", "cave_spider"]},
	"fungal": {big = ["great_rock_beetle"], small = ["great_rock_beetle"]},
}

const SIGHT := 15.0
const SIGHT_DARK := 8.0
const HEAR_RUN := 12.0
const HEAR_WALK := 6.0
const HEAR_DIG := 20.0
const LEASH := 40.0
const GIVE_UP := 10.0  ## seconds without reaching you before going home
const WANDER_RADIUS := 15.0


## Crystal variants (combat doc 7): crystals grow on their backs, glow, and add a power.
## shortcut: gem drops wait for the gem system; elemental resists are stored but only matter
## once players deal elemental damage.
const VARIANTS := {
	"red": {name = "Ember-crested", color = Color(1.0, 0.35, 0.2), extra_damage = 5, buildup = {burn = 30}, crystal = "crystal_red", count = 4, fire = 0.75, frost = -0.5},
	"blue": {name = "Rime-crested", color = Color(0.4, 0.75, 1.0), extra_damage = 5, buildup = {chill = 30}, crystal = "crystal_blue", count = 4, frost = 0.75, fire = -0.5},
	"green": {name = "Blight-crested", color = Color(0.4, 1.0, 0.45), extra_damage = 4, buildup = {poison = 35}, crystal = "crystal_green", count = 4, poison = 1.0, fire = -0.25},
	"violet": {name = "Shift-crested", color = Color(0.7, 0.45, 1.0), blink = 8.0, crystal = "crystal_violet", count = 3, pierce_mult = 1.25},
	"amber": {name = "Amber-crested", color = Color(1.0, 0.7, 0.25), armor = 40, crystal = "crystal_amber", count = 4, blunt_mult = 1.25},
}
const VARIANT_STATS := {hp = 1.4, damage = 1.1, stun = 1.2, xp = 2, armor = 25}  ## (armor: crested ones are elites, F532; amber has its own)
## [chance a spawned monster is a crystal variant, colour split] per biome (doc 7.3).
const VARIANT_CHANCE := {
	"mossy": [0.04, {red = 0.3, blue = 0.3, amber = 0.3, violet = 0.1}],
	"fungal": [0.07, {green = 0.35, red = 0.2, violet = 0.2, amber = 0.15, blue = 0.1}],
}


## Two dice (0..1) -> "" (normal) or a variant colour.
static func roll_variant(biome: String, chance_roll: float, colour_roll: float) -> String:
	var c: Array = VARIANT_CHANCE.get(biome, [0.0, {}])
	if chance_roll >= c[0]:
		return ""
	var acc := 0.0
	for colour in c[1]:
		acc += c[1][colour]
		if colour_roll < acc:
			return colour
	return c[1].keys()[-1]


## A monster's final numbers, with leader/variant boosts applied. Used for damage math.
static func target_stats(id: String, leader: bool, variant: String = "") -> Dictionary:
	var m: Dictionary = info(id)
	var v: Dictionary = VARIANTS.get(variant, {})
	return {armor = m.armor + (LEADER.armor if leader else 0) + (v.get("armor", VARIANT_STATS.armor) if variant != "" else 0), slash = m.slash,
		blunt = m.blunt * v.get("blunt_mult", 1.0), pierce = m.pierce * v.get("pierce_mult", 1.0),
		fire = v.get("fire", m.fire), frost = v.get("frost", m.frost), poison = v.get("poison", m.poison)}


static func max_hp(id: String, leader: bool, variant: String = "", players := 1) -> float:
	return info(id).hp * (LEADER.hp if leader else 1.0) * (VARIANT_STATS.hp if variant != "" else 1.0) 		* (1.0 + PARTY_HP[rank(id, leader, variant)] * (clampi(players, 1, 4) - 1))


## F532 (owner, chat 16): only elites and bosses wear armor. Elite = a pack leader, a crested one, or one marked
## elite (the Great Rock Beetle); boss = marked boss.
static func rank(id: String, leader: bool, variant: String = "") -> String:
	var m: Dictionary = info(id)
	if m.get("boss", false):
		return "boss"
	return "elite" if leader or variant != "" or m.get("elite", false) else "normal"


## More health for each extra player in the world (owner, chat 16: bosses the most, elites a bit, the rest 30%).
const PARTY_HP := {normal = 0.30, elite = 0.50, boss = 0.75}


## How many players are in the world now (1 when there's no game running, e.g. in tests).
static func party() -> int:
	var auth := GameAuthority.instance
	return clampi(auth.players.size(), 1, 4) if auth else 1


## Which food guard protects you from this creature (food plan: eat its meat, fear it less). "" = none.
static func food_guard(kind: String) -> String:
	if kind.contains("bat"):
		return "bat"
	if kind.contains("beetle"):
		return "beetle"
	if kind.contains("spider"):
		return "spider"
	if kind.contains("snail"):
		return "snail"
	return ""
