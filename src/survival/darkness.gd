class_name Darkness
## F293 (owner, Nov 19): standing in the dark hurts. No healing at all, and every action costs 50% more stamina.
## "In the dark" = no real light reaches you: your own lantern is empty, put away or missing, and no torch, lamp,
## campfire, glowing crystal, glowing tree or shrine is close enough. Creatures' own glow doesn't count.
## Every light that counts calls Darkness.mark() when it is made.

const GROUP := "light_source"
const STAMINA_MULT := 1.5  ## stamina costs in the dark
const REACH := 0.75  ## a light reaches this part of its range (its edge is too dim to count)


## `min_energy`: below this brightness the light doesn't count (an empty lantern still glows a little).
static func mark(l: Light3D, min_energy := 0.3) -> void:
	l.add_to_group(GROUP)
	l.set_meta("min_energy", min_energy)


static func is_lit(tree: SceneTree, pos: Vector3) -> bool:
	for n in tree.get_nodes_in_group(GROUP):
		var l := n as OmniLight3D
		if l == null or not l.is_visible_in_tree():
			continue
		if l.light_energy < float(l.get_meta("min_energy", 0.3)):
			continue
		var r := l.omni_range * REACH
		if l.global_position.distance_squared_to(pos) <= r * r:
			return true
	return false
