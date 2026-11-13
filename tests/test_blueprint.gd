extends TestCase
## Blueprints: capture, save, load (with the safety checks), and turning.

var ground := func(p: Vector3) -> float: return p.y  # rock below y = 0


func _hut() -> Structure:
	var s := Structure.new()
	s.add(1, "floor", "cut_stone", Vector3(1, 0, 1), 0, true)
	s.add(2, "wall", "plank_root", Vector3(1, 0.25, 0), 0, false)
	s.add(3, "wall", "plank_root", Vector3(0, 0.25, 1), 1, false)
	s.add(4, "doorway", "plank_root", Vector3(1, 0.25, 2), 0, false)
	s.add(99, "floor", "cut_stone", Vector3(21, 0, 21), 0, true)  # far away: not in the box
	return s


func test_capture_and_cost() -> void:
	var bp := Blueprint.capture(_hut(), ground, Vector3(-1, 0, -1), Vector3(3, 3, 3), "Tiny Hut")
	check_eq(bp.pieces.size(), 4, "4 pieces inside the box")
	check_eq(bp.size, Vector3(4, 3, 4), "box size")
	check_eq(bp.cost(), {cut_stone = 4, plank_root = 12, copper_ingot = 2}, "cost adds up")
	check_eq(bp.air.size(), 48, "one air bit per cell")
	check(bp.air[0] == 1, "cells above the ground are open air")


func test_json_round_trip() -> void:
	var bp := Blueprint.capture(_hut(), ground, Vector3(-1, 0, -1), Vector3(3, 3, 3), "Tiny Hut")
	var r := Blueprint.from_json(bp.to_json())
	check(r.ok, "loads back: " + r.error)
	if r.ok:
		var b2: Blueprint = r.blueprint
		check_eq(b2.pieces.size(), 4, "same pieces")
		check_eq(b2.air, bp.air, "same air mask")
		check_eq(b2.name, "Tiny Hut", "same name")


func test_bad_files_are_refused() -> void:
	var good := Blueprint.capture(_hut(), ground, Vector3(-1, 0, -1), Vector3(3, 3, 3), "Tiny Hut").to_json()
	check(not Blueprint.from_json("hello").ok, "not JSON")
	check(not Blueprint.from_json("[1,2,3]").ok, "JSON but not a blueprint")
	check(not Blueprint.from_json(good.replace("\"plank_root\"", "\"gold_brick\"")).ok, "unknown material")
	check(not Blueprint.from_json(good.replace("\"wall\"", "\"rocket\"")).ok, "unknown piece")
	var d: Dictionary = JSON.parse_string(good)
	d.pieces[0].pos = [999, 0, 0]
	check(not Blueprint.from_json(JSON.stringify(d)).ok, "piece outside the box")
	d = JSON.parse_string(good)
	d.size = [100, 3, 4]
	check(not Blueprint.from_json(JSON.stringify(d)).ok, "box too big")
	d = JSON.parse_string(good)
	d.air.rle = [1]
	check(not Blueprint.from_json(JSON.stringify(d)).ok, "air mask wrong length")
	d = JSON.parse_string(good)
	d.pieces[0].rot = 7
	check(not Blueprint.from_json(JSON.stringify(d)).ok, "bad rotation")
	d = JSON.parse_string(good)
	d.pieces[0].pos = [0.5, 0, 0]
	check_eq(Blueprint.from_json(JSON.stringify(d)).error, "The file is damaged (checksum doesn't match).", "tampered file caught")


func test_turning_a_blueprint() -> void:
	var bp := Blueprint.capture(_hut(), ground, Vector3(-1, 0, -1), Vector3(3, 3, 3), "Tiny Hut")
	var placed := bp.world_pieces(Vector3(10, 0, 10), 1)
	var wall: Dictionary = placed[1]
	check_eq(wall.rot, 1, "a quarter turn turns the pieces too")
	check_eq(placed.size(), 4, "all pieces placed")
	var cells := bp.carve_cells(Vector3(10, 0, 10), 0)
	check(cells.size() > 0, "open air cells to carve")


func test_starter_blueprint_file_loads() -> void:
	var f := FileAccess.open("res://blueprints/small_rootwood_lodge.dwbp", FileAccess.READ)
	check(f != null, "the starter blueprint ships with the game")
	if f:
		var r := Blueprint.from_json(f.get_as_text())
		check(r.ok, "starter blueprint is valid: " + r.error)
