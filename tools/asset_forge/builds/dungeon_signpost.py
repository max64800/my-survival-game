# The dungeon signpost (F844, owner Nov 25: "a sign at each dungeon's door: how hard it is and which recipe is inside").
# A chunky hewn post in a little stone cairn, a crossbar on top with three skulls (the game shows 1, 2 or 3 of them:
# small / medium / big dungeon), and a thick board where the game paints the recipe's picture. A green-painted tick
# sits in the board's corner (the game shows it once the recipe is learned).
#
#   blender --background --factory-startup --python builds/dungeon_signpost.py -- [out=<folder>] [pics=<folder>]
#
# Game axes: x across, y up, z = front (+z faces the cave). Origin bottom-centre.
# Parts: "post" (post, cairn, crossbar, board, pegs), "skull_l", "skull_mid", "skull_r", "tick".
# The board's front face is at z = BOARD_FRONT, centre (0, BOARD_Y): the game lays the recipe picture just in front.
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import dungeon_stonehold as D  # noqa: E402  (its save() and pics options; also loads the Stonehold kit)
import stonehold_v2 as S  # noqa: E402
import shack_v2 as SH  # noqa: E402  (sets K.S = "shack")
from decor_nov21_b import skull  # noqa: E402
from decor_nov21_a import BONE  # noqa: E402

J = K.J
BOARD_Y = 1.0         # = DungeonBuild.SIGN_BOARD (the picture's centre height)
BOARD_FRONT = 0.135   # = DungeonBuild.SIGN_FRONT
PIC_X = -0.07         # = DungeonBuild.SIGN_PIC_X (the picture sits left of the tick, about 0.28 m wide)
SKULL_X = (-0.22, 0.0, 0.22)


def names():
	return {o.name for o in bpy.data.objects if o.type == "MESH"}


def bark():
	return kit.tex_mat("shackbark", K.rng.choice(("v0", "v1", "v2", "v3")))


def plank():
	return kit.tex_mat("shackplank", K.rng.choice(("v1", "v3", "v5")))


def signpost():
	groups = {}
	before = names()
	# the cairn: six chunky stones round the foot, a smaller ring on top (each one sits on the one below)
	for k in range(6):
		a = k * 1.047 + 0.3
		import math
		S.block((math.cos(a) * 0.2, 0.08, math.sin(a) * 0.2), (0.17 + J(0.02), 0.16, 0.15 + J(0.02)), cut=0.03, tilt=1.5, free="xyz")
	for k in range(4):
		a = k * 1.571 + 0.8
		import math
		S.block((math.cos(a) * 0.13, 0.205, math.sin(a) * 0.13), (0.12, 0.1, 0.11), cut=0.025, tilt=2.0, free="xyz")
	# the post: one hewn beam (bark left on its corners), chopped flat at the top under the crossbar
	SH.real_log((0, 0.0, 0), (0, 1.52, 0), 0.095, "hewn", m=bark(), stub=False)
	# the crossbar the skulls sit on, notched into the post (passes through it)
	SH.real_log((-0.36, 1.46, 0.0), (0.36, 1.46, 0.0), 0.065, "hewn", m=bark(), stub=False)
	# the board: a thick split plank pegged to the post's front (1 cm into the post, no gap)
	b = K.blk((0, BOARD_Y, BOARD_FRONT - 0.03), (0.66, 0.4, 0.06), plank(), bevel=0.012, rz=J(1.5))
	b["role"] = "board"
	# a darker band round the board's face (the frame round the picture), 1 cm proud so nothing shares a face
	for (cx, cy, sx, sy) in ((0, BOARD_Y + 0.175, 0.64, 0.04), (0, BOARD_Y - 0.175, 0.64, 0.04),
			(-0.3, BOARD_Y, 0.04, 0.31), (0.3, BOARD_Y, 0.04, 0.31)):
		K.blk((cx, cy, BOARD_FRONT + 0.004), (sx, sy, 0.012), kit.tex_mat("shackplank", "v7"), bevel=0.003)
	for x in (-0.255, 0.255):
		for y in (BOARD_Y + 0.13, BOARD_Y - 0.13):
			SH.peg(x, y, BOARD_FRONT + 0.008, "z")
	for o in [bpy.data.objects[n] for n in names() - before]:
		kit._uv_box(o, 0.6)
	groups["post"] = names() - before
	# three skulls, each on an iron spike driven into the crossbar (the spike hides inside the skull)
	for nm, x in zip(("skull_l", "skull_mid", "skull_r"), SKULL_X):
		before = names()
		kit.cylinder(0.012, 0.12, K.G((x, 1.55, 0.0)), D.iron(), verts=8, bevel=0.002)
		skull(K.G((x, 1.62 + 0.02 * (x == 0), 0.0)), 0.85, BONE(J(0.06)), face=(J(0.15), -1, 0))
		groups[nm] = names() - before
	# the tick: a green-painted check mark in the board's lower right corner (two short bars, 1 cm proud)
	before = names()
	g = bpy.data.materials.new("tick_green")   # a bright painted green, easy to see across the cave
	g.use_nodes = True
	g.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.2, 0.72, 0.16, 1)
	g.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
	K.blk((0.16, BOARD_Y - 0.03, BOARD_FRONT + 0.012), (0.095, 0.034, 0.016), g, bevel=0.005, rz=-45)
	K.blk((0.225, BOARD_Y + 0.0, BOARD_FRONT + 0.013), (0.155, 0.034, 0.016), g, bevel=0.005, rz=56)
	groups["tick"] = names() - before
	return groups


BUILDS = {"signpost_skulls": signpost}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		for o in list(bpy.data.objects):
			bpy.data.objects.remove(o, do_unlink=True)
		K.rng.seed(sum(map(ord, name)))
		kit.reset()
		groups = fn()
		parts = D.save(name, groups)
		if D.PICS:
			import cave_plants as cp
			D.PICS.mkdir(parents=True, exist_ok=True)
			cp.OUT = D.PICS
			cp.pictures(name, parts)
