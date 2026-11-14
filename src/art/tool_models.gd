class_name ToolModels
## The things a dwarf holds: pickaxes, axes, swords, maces, spears, hammers, shields,
## crossbows, and a small lump for anything else (food, crystals…). Built from simple
## shapes but shaped like the real thing, with the shared painted look (Look.mat):
## wooden handles with a leather grip, metal (or stone/copper) heads.
## Convention: the handle runs along +Y from the hand (0,0,0); the "business end" is up.
## Sizes in metres, before the 0.8 hand scale of the rigged dwarf.

const WOOD := Color(0.45, 0.31, 0.19)
const LEATHER := Color(0.30, 0.19, 0.11)
const IRON := Color(0.55, 0.55, 0.58)


## A finished model for `look` (Combat.weapon_of / Items.kind), with `col` = the item's colour.
static func build(look: String, col: Color, layers: int) -> Node3D:
	var root := Node3D.new()
	var head_surface := _head_surface(col)
	match look:
		"pickaxe":
			_handle(root, 0.78)
			_add(root, _box(Vector3(0.075, 0.09, 0.085)), col, head_surface, Vector3(0, 0.74, 0))
			for s in [-1.0, 1.0]:  # two curved spikes
				_add(root, _cone(0.028, 0.27, 4), col, head_surface, Vector3(0, 0.72, s * 0.15), Vector3(s * deg_to_rad(-100), 0, 0))
		"axe", "axe_2h":
			var big := look == "axe_2h"
			_handle(root, 0.95 if big else 0.72)
			var top := 0.88 if big else 0.66
			_add(root, _box(Vector3(0.05, 0.09, 0.07)), col, head_surface, Vector3(0, top, 0))
			var blade := _add(root, _cyl(0.0, 0.17 if big else 0.13, 0.05, 3), col, head_surface, Vector3(0, top, -0.12), Vector3(0, 0, PI / 2.0))
			blade.scale = Vector3(1, 1, 1.6)
			if big:
				_add(root, _cyl(0.0, 0.12, 0.05, 3), col, head_surface, Vector3(0, top, 0.11), Vector3(PI, 0, PI / 2.0))
		"sword":
			_grip(root, 0.16)
			_add(root, _box(Vector3(0.24, 0.035, 0.05)), IRON, "metal", Vector3(0, 0.16, 0))  # cross guard
			var blade := _add(root, _cyl(0.035, 0.045, 0.62, 4), col, head_surface, Vector3(0, 0.49, 0), Vector3(0, PI / 4.0, 0))
			blade.scale = Vector3(1, 1, 0.3)
			var tip := _add(root, _cone(0.035, 0.12, 4), col, head_surface, Vector3(0, 0.86, 0), Vector3(0, PI / 4.0, 0))
			tip.scale = Vector3(1, 1, 0.3)
			_add(root, _sphere(0.035), IRON, "metal", Vector3(0, -0.03, 0))  # pommel
		"mace", "mace_2h":
			var big := look == "mace_2h"
			_handle(root, 0.85 if big else 0.6)
			var top := 0.85 if big else 0.6
			var r := 0.13 if big else 0.095
			_add(root, _sphere(r), col, head_surface, Vector3(0, top, 0))
			for i in 6:  # flanges
				var a := i * TAU / 6.0
				_add(root, _cone(r * 0.35, r * 0.9, 4), col, head_surface,
					Vector3(cos(a) * r, top, sin(a) * r), Vector3(0, -a, -PI / 2.0))
		"spear":
			_handle(root, 1.5, 0.022)
			var head := _add(root, _cone(0.05, 0.28, 4), col, head_surface, Vector3(0, 1.62, 0))
			head.scale = Vector3(1, 1, 0.35)
			_add(root, _cyl(0.03, 0.03, 0.06, 6), LEATHER, "leather", Vector3(0, 1.47, 0))
		"hammer":
			_handle(root, 0.6)
			_add(root, _box(Vector3(0.11, 0.11, 0.2)), col, head_surface, Vector3(0, 0.58, 0))
			for z in [-0.09, 0.09]:
				_add(root, _box(Vector3(0.125, 0.125, 0.025)), IRON, "metal", Vector3(0, 0.58, z))
		"shield":
			# Round wooden shield strapped to the forearm: it faces outward (the back of the hand).
			var trim := IRON if Look.guess(col) == "wood" else col
			_add(root, _cyl(0.32, 0.32, 0.04, 14), WOOD, "wood", Vector3(0.07, 0.1, 0), Vector3(0, 0, PI / 2.0))
			var band := _add(root, _torus(0.3, 0.335), trim, "metal", Vector3(0.07, 0.1, 0), Vector3(0, 0, PI / 2.0))
			band.scale = Vector3(1, 1.2, 1)
			_add(root, _sphere(0.07), trim, "metal", Vector3(0.1, 0.1, 0))
		"crossbow":
			_add(root, _box(Vector3(0.06, 0.06, 0.55)), WOOD, "wood", Vector3(0, 0.05, -0.15))
			var bow := _add(root, _cyl(0.018, 0.018, 0.6, 6), col, head_surface, Vector3(0, 0.07, -0.38), Vector3(0, 0, PI / 2.0))
			bow.scale = Vector3(1, 1, 1)
			_add(root, _box(Vector3(0.04, 0.12, 0.05)), LEATHER, "leather", Vector3(0, -0.04, 0.02))
		"fists", "":
			pass
		_:
			# Food, crystals, potions, ore…: a small lump of the item's colour in the hand.
			_add(root, _sphere(0.07), col, "", Vector3(0, 0.06, 0)).scale = Vector3(1, 0.8, 1.1)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		mi.layers = layers
	return root


## Stone tools look like stone, copper/silver/iron like metal.
static func _head_surface(col: Color) -> String:
	return "stone" if col.s < 0.12 and col.v < 0.7 else "metal"


static func _handle(root: Node3D, length: float, r: float = 0.025) -> void:
	_add(root, _cyl(r * 0.9, r, length, 7), WOOD, "wood", Vector3(0, length * 0.5 - 0.12, 0))
	_add(root, _cyl(r * 1.35, r * 1.35, 0.17, 7), LEATHER, "leather", Vector3(0, 0.0, 0))  # grip wrap


static func _grip(root: Node3D, length: float) -> void:
	_add(root, _cyl(0.022, 0.024, length, 7), LEATHER, "leather", Vector3(0, length * 0.5 - 0.04, 0))


static func _add(root: Node3D, mesh: Mesh, col: Color, surface: String, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Look.mat(col, surface)
	mi.position = pos
	mi.rotation = rot
	root.add_child(mi)
	return mi


static func _cyl(top: float, bottom: float, h: float, seg: int) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _cone(r: float, h: float, seg: int) -> Mesh:
	return _cyl(0.0, r, h, seg)


static func _box(s: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = s
	return m


static func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 6
	return m


static func _torus(inner: float, outer: float) -> Mesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 18
	m.ring_segments = 6
	return m
