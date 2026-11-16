"""Give a finished .glb model its size in the game (by Claude 3, Nov 16, 2026).

    from code: import glb_scale; glb_scale.set_scale(path, 0.88)

Used by build_creatures.py (GAME_SCALE): the baked Rock Beetle is 1.54 m long, the game's beetle and its collision
are ~1.36 m, so the installed model is wrapped in one parent node scaled to 0.88. The meshes are not touched.
"""
import json
import struct


def set_scale(path, scale):
	"""Wrap the whole model in one parent node scaled by `scale` (the game's size for it), without touching the meshes.
	The moving parts keep their names and hinges (the game finds them anywhere under the model)."""
	if abs(scale - 1.0) < 1e-6:
		return
	d = open(path, "rb").read()
	jl = struct.unpack_from("<I", d, 12)[0]
	js = json.loads(d[20:20 + jl])
	rest = d[20 + jl:]
	scn = js["scenes"][js.get("scene", 0)]
	js["nodes"].append({"name": "art_scale", "scale": [scale] * 3, "children": scn["nodes"]})
	scn["nodes"] = [len(js["nodes"]) - 1]
	jb = json.dumps(js, separators=(",", ":")).encode()
	while len(jb) % 4:
		jb += b" "
	open(path, "wb").write(struct.pack("<III", 0x46546C67, 2, 20 + len(jb) + len(rest)) + struct.pack("<II", len(jb), 0x4E4F534A) + jb + rest)
