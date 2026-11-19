# The floor of the glow groves (owner, Nov 19, 2026: rocks, pebbles, grass, ferns and plants "added alongside ours",
# repainted to match; decisions in docs/research/asset-picks-placement.md). Free CC0 pack models (KayKit Forest
# Nature, Quaternius Stylized Nature MegaKit, flo-bit; sources in tools/asset_forge/packs/) rebuilt by script
# (MODEL-RULES rule 1 as bent for free packs):
#   rocks and pebbles: the pack shape, a little hand-made wobble, repainted with our hand-painted stone pictures
#   plants: the pack's leaf cards kept (cut-out edges), darkened a little for the cave
#
#   blender --background --factory-startup --python builds/grove_dressing.py -- <out_dir> [only=grock_a,...]
import sys
import zlib
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import glow_trees as gt  # noqa: E402  (import, wobble, export helpers)
import kit  # noqa: E402

Q = gt.Q
KF = gt.PACKS / "kaykit_forest_nature"
F = gt.F
STONES = [("greystone", "a"), ("warmstone", "b"), ("slate", "a"), ("basalt", "b"), ("limestone", "c"), ("greystone", "c"),
	("amberrock", "a"), ("warmstone", "a"), ("slate", "b"), ("basalt", "a")]

# (every name spelled out: the model-rules test finds a model's build script by its name)
ROCKS = {
	"grock_a": KF / "Rock_3_A_Color1.gltf",
	"grock_b": KF / "Rock_3_B_Color1.gltf",
	"grock_c": KF / "Rock_3_C_Color1.gltf",
	"grock_d": KF / "Rock_3_D_Color1.gltf",
	"grock_e": KF / "Rock_3_E_Color1.gltf",
	"grock_f": KF / "Rock_3_F_Color1.gltf",
	"grock_g": KF / "Rock_3_G_Color1.gltf",
	"grock_h": KF / "Rock_3_H_Color1.gltf",
	"grock_i": KF / "Rock_3_I_Color1.gltf",
	"grock_j": KF / "Rock_3_J_Color1.gltf",
	"grock_k": KF / "Rock_3_K_Color1.gltf",
	"grock_l": KF / "Rock_3_L_Color1.gltf",
	"grock_m": KF / "Rock_3_M_Color1.gltf",
	"grock_n": KF / "Rock_3_N_Color1.gltf",
	"grock_o": KF / "Rock_3_O_Color1.gltf",
	"grock_p": KF / "Rock_3_P_Color1.gltf",
	"grock_q": KF / "Rock_3_Q_Color1.gltf",
	"grock_r": KF / "Rock_3_R_Color1.gltf",
	"grock_medium_1": Q / "Rock_Medium_1.gltf",
	"grock_medium_2": Q / "Rock_Medium_2.gltf",
	"grock_medium_3": Q / "Rock_Medium_3.gltf",
}
PEBBLES = {
	"gpebble_round_1": Q / "Pebble_Round_1.gltf",
	"gpebble_round_2": Q / "Pebble_Round_2.gltf",
	"gpebble_round_3": Q / "Pebble_Round_3.gltf",
	"gpebble_round_4": Q / "Pebble_Round_4.gltf",
	"gpebble_round_5": Q / "Pebble_Round_5.gltf",
	"gpebble_square_1": Q / "Pebble_Square_1.gltf",
	"gpebble_square_2": Q / "Pebble_Square_2.gltf",
	"gpebble_square_3": Q / "Pebble_Square_3.gltf",
	"gpebble_square_4": Q / "Pebble_Square_4.gltf",
	"gpebble_square_5": Q / "Pebble_Square_5.gltf",
	"gpebble_square_6": Q / "Pebble_Square_6.gltf",
}
PLANTS = {
	"gplant_grass_short": Q / "Grass_Common_Short.gltf", "gplant_grass_tall": Q / "Grass_Common_Tall.gltf",
	"gplant_grass_c": KF / "Grass_2_C_Color1.gltf", "gplant_grass_d": KF / "Grass_2_D_Color1.gltf",
	"gplant_clover_1": Q / "Clover_1.gltf", "gplant_clover_2": Q / "Clover_2.gltf", "gplant_fern": Q / "Fern_1.gltf",
	"gplant_leafy_1": Q / "Plant_1.gltf", "gplant_leafy_1_big": Q / "Plant_1_Big.gltf",
	"gplant_flat_7": Q / "Plant_7.gltf", "gplant_flat_7_big": Q / "Plant_7_Big.gltf",
	"gplant_flower_bush": Q / "Bush_Common_Flowers.gltf",
	"gfungus_shelf": Q / "Mushroom_Laetiporus.gltf", "gfungus_cap": F / "mushroom_5.glb",
}


def rock(name, src, out_dir):
	obj = gt.import_tree(src)
	k = zlib.crc32(name.encode())
	gt.wobble(obj, 0.025, k % 100)
	kind, variant = STONES[k % len(STONES)]
	mat = kit.tex_mat(kind, variant)
	obj.data.materials.clear()
	obj.data.materials.append(mat)
	kit._uv_box(obj, mat["tile"])
	kit.save(str(Path(out_dir) / f"{name}.glb"))


def plant(name, src, out_dir):
	obj = gt.import_tree(src)
	for s in obj.material_slots:  # a little darker for the cave (they sit in the groves' coloured light)
		m = s.material
		if m and m.node_tree:
			b = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
			if b and not b.inputs["Base Color"].is_linked:
				c = b.inputs["Base Color"].default_value
				b.inputs["Base Color"].default_value = (c[0] * 0.75, c[1] * 0.75, c[2] * 0.75, c[3])
	out = gt.export(str(Path(out_dir) / f"{name}.glb"), [obj])
	_cutout_all(str(Path(out_dir) / f"{name}.glb"))
	return out


def _cutout_all(path):
	"""Leaf cards with see-through edges: every textured material is a double-sided cut-out."""
	import json
	import struct
	b = bytearray(Path(path).read_bytes())
	n = struct.unpack_from("<I", b, 12)[0]
	j = json.loads(b[20:20 + n])
	for m in j.get("materials", []):
		if m.get("pbrMetallicRoughness", {}).get("baseColorTexture") is not None:
			m["alphaMode"] = "MASK"
			m["alphaCutoff"] = 0.5
			m["doubleSided"] = True
	s = json.dumps(j, separators=(",", ":")).encode()
	s += b" " * ((4 - len(s) % 4) % 4)
	rest = b[20 + n:]
	Path(path).write_bytes(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(s) + len(rest)) + struct.pack("<II", len(s), 0x4E4F534A) + s + rest)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	out_dir = args[0] if args else str(Path(__file__).resolve().parents[3] / "assets" / "models" / "cave")
	every = {**{k: ("rock", v) for k, v in {**ROCKS, **PEBBLES}.items()}, **{k: ("plant", v) for k, v in PLANTS.items()}}
	only = next((a.split("=", 1)[1].split(",") for a in args if a.startswith("only=")), list(every))
	for n in only:
		kind, src = every[n]
		(rock if kind == "rock" else plant)(n, src, out_dir)
