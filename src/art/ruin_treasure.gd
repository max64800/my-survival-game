class_name RuinTreasure
## Treasure and lost things in old places (owner, Nov 19, 2026; batch 4 in docs/research/asset-picks-placement.md).
## Ruins and great halls: a treasure corner by the loot chest (coins, candles, books, a scroll, a chalice) and a few
## books and scrolls lying about. Camps: a traveller's things by the bedroll (mug, plate, cutlery, map, pouch).
## Only looks (no touching, no loot): the chest holds the loot. Models: tools/asset_forge/builds/treasure.py.
## Same dice on every computer (co-op friends see the same things).

const CHEST_SPOT := Vector3(1.5, 0, 1.0)  ## where GameAuthority.seed_poi_loot puts the loot chest (from the place's middle)
const CORNER := ["tr_coins", "tr_coins_wide", "tr_candle_tall", "tr_candle_short", "tr_books_stack_1", "tr_chalice",
	"tr_scroll_1", "tr_candlestick", "tr_key_copper"]
const ABOUT := ["tr_books_row_1", "tr_books_row_2", "tr_books_row_3", "tr_books_stack_2", "tr_book_red", "tr_book_clasped",
	"tr_scroll_2", "tr_map_blank", "tr_mug", "tr_key_iron"]
const CAMP := ["tr_mug", "tr_plate", "tr_fork", "tr_knife", "tr_spoon", "tr_map", "tr_pouch", "tr_candle_short", "tr_scroll_1"]
const SEEN_TO := 45.0  ## small things: drawn up to this far away (m)


## Things for place `p` (type "ruin", "great_hall" or "camp"): [{model, at (offset from the place's middle), spin}].
static func plan(p: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match String(p.type):
		"ruin", "great_hall":
			var n := rng.randi_range(4, 6)
			var corner := CORNER.duplicate()
			for i in n:  # around the loot chest, never on it
				var a := rng.randf_range(0.0, TAU)
				var d := rng.randf_range(0.75, 1.3)
				var m: String = corner.pop_at(rng.randi_range(0, corner.size() - 1))
				out.append({model = m, at = CHEST_SPOT + Vector3(cos(a), 0, sin(a)) * d, spin = rng.randf_range(0.0, TAU)})
			var reach := 3.0 if p.type == "ruin" else 8.0  # (the ruin's walls stand 3.6 m out)
			for i in rng.randi_range(3, 5):  # lying about the hall
				var a := rng.randf_range(0.0, TAU)
				var at := Vector3(cos(a), 0, sin(a)) * rng.randf_range(1.2, reach)
				if at.distance_to(CHEST_SPOT) < 1.0:
					continue
				out.append({model = ABOUT[rng.randi_range(0, ABOUT.size() - 1)], at = at, spin = rng.randf_range(0.0, TAU)})
		"camp":
			var things := CAMP.duplicate()
			for i in rng.randi_range(4, 6):  # beside the bedroll (at x 1.2) and the ashes (at x -0.8)
				var m: String = things.pop_at(rng.randi_range(0, things.size() - 1))
				var at := Vector3(rng.randf_range(0.0, 0.7), 0, rng.randf_range(-1.2, 1.2) + (1.6 if rng.randf() < 0.5 else -1.6) * 0.5)
				out.append({model = m, at = at, spin = rng.randf_range(0.0, TAU)})
	return out


## Its own dice per place (not shared with the columns and walls), so the ground it takes is known before it's built.
static func rng_for(p: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Vector3i((p.pos as Vector3).round()), int(p.get("id", 0)), "treasure"])
	return rng


## Where GameAuthority.seed_poi_loot puts place `p`'s loot chest.
static func chest_spot(maker: CaveMaker, p: Dictionary) -> Vector3:
	var c: Vector3 = p.pos
	return maker.find_floor(c.x + CHEST_SPOT.x, c.z + CHEST_SPOT.z, c.y + 3.0)


const CHEST_ROOM := 0.75  ## ground a loot chest takes (it's 1.0 x 0.7 m)
const THING_ROOM := 0.3  ## ground one treasure thing takes


## Ground the old places' loot chests and treasure take in this cave: [{pos, r}] (owner, Nov 19: mushrooms and grass
## grew through a ruin chest). Boulders and glowing mushrooms keep off it; pebbles, plants and mushroom grass get out
## of the way when the chest or thing is put down (World.ground_taken). Test: test_clutter_keeps_clear_of_boxes.
static func keep_clear(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in maker.pois:
		if p.type == "ruin" or p.type == "camp":
			out.append({pos = chest_spot(maker, p), r = CHEST_ROOM})
		if p.type == "ruin" or p.type == "camp" or p.type == "great_hall":
			var c: Vector3 = p.pos
			for t in plan(p, rng_for(p)):
				out.append({pos = maker.find_floor(c.x + t.at.x, c.z + t.at.z, c.y + 1.5), r = THING_ROOM})
	return out


## Puts the planned things into `root` (the place's node). on_floor(p, offset) -> where the floor is (PoiField).
static func dress(root: Node3D, p: Dictionary, on_floor: Callable) -> void:
	for t in plan(p, rng_for(p)):
		var scene: PackedScene = load("res://assets/models/treasure/%s.glb" % t.model) if ResourceLoader.exists("res://assets/models/treasure/%s.glb" % t.model) else null
		if scene == null:
			continue
		var m := scene.instantiate() as Node3D
		root.add_child(m)
		m.position = _settle(on_floor.get_object().maker, p, on_floor.call(p, t.at))  # (offsets from the place's middle)
		m.rotation.y = t.spin
		GroundSnap.take((p.pos as Vector3) + m.position, THING_ROOM)  # pebbles, plants and mushroom grass make room
		for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			mi.visibility_range_end = SEEN_TO
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The floor finder works in 25 cm steps: small things (a coin pile is 10 cm) would sink in. Find the rock in 2 cm steps.
static func _settle(maker: CaveMaker, p: Dictionary, off: Vector3) -> Vector3:
	var c: Vector3 = p.pos
	var y := off.y + 0.4
	for i in 60:
		if maker.sdf_at(c + Vector3(off.x, y - 0.02, off.z)) <= 0.0:
			break
		y -= 0.02
	return Vector3(off.x, y, off.z)
