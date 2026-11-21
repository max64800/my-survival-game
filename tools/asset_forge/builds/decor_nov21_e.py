# Cosy dwarf-home decor (Nov 21, group e): bedroom, washroom, study, tavern and kitchen pieces in warm wood and stone.
#   blender --background --factory-startup --python builds/decor_nov21_e.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (mug_rack) have a flat back at +Y so they sit flush on a wall.
# Owner fix round (Nov 21, scores 2-9): bathtub_barrel + washbasin empty, boot_rack without boots, bread_oven
# without bread, bunk_bed bare slatted frames, cooking_spit more detail, fur_rug -> woven rug with leather border,
# hammock rope net + rings, storage_trunk broken and empty, tap_keg_stand plain tap, wardrobe one wood family.
# Deleted by the owner: armchair_fur, coat_rack, dressing_mirror, footstool, hanging_sausages.
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, cband, disc, ember_bed, kit, log, mesh, mesh_cloth, plank, rivet, rng, stone, water_disc  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import CU, IRON, WOOD, cushion, legs4, plank_top, rope_tie, stone_blocks  # noqa: E402
from decor_nov21_f import group, lathe  # noqa: E402

LINEN = (0.85, 0.8, 0.68)


def bar(pts, w, t, m, x=0.0):
	"""A bent bar along (y, z) points (rockers): w wide in x, t thick."""
	v, n = [], len(pts)
	for i, (y, z) in enumerate(pts):
		a, b = pts[max(i - 1, 0)], pts[min(i + 1, n - 1)]
		ty, tz = b[0] - a[0], b[1] - a[1]
		ln = math.hypot(ty, tz)
		ny, nz = -tz / ln, ty / ln
		for sx, sn in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
			v.append((x + sx * w / 2, y + ny * sn * t / 2, z + nz * sn * t / 2))
	f = [(0, 1, 2, 3), tuple(range(4 * n - 4, 4 * n))]
	f += [(i * 4 + k, i * 4 + (k + 1) % 4, (i + 1) * 4 + (k + 1) % 4, (i + 1) * 4 + k) for i in range(n - 1) for k in range(4)]
	return mesh(v, f, m)


def floor_post(top):
	"""Wall pieces also stand on a short post, so they never float when placed in the open (back stays flat at +Y)."""
	B((0.06, 0.04, top), (0, 0.03, top / 2), T("wood", "dark"), bevel=0.008)
	B((0.3, 0.2, 0.04), (0, -0.04, 0.02), T("wood", "dark"), bevel=0.008)


def mug(x, y, z, m=None):
	m = m or T("wood", "c")
	kit.cylinder(0.05, 0.12, (x, y, z + 0.06), m, verts=10, bevel=0.008)
	kit.ring(0.051, 0.008, (x, y, z + 0.03), IRON(), seg=12)
	kit.ring(0.035, 0.01, (x + 0.065, y, z + 0.06), m, rot=(90, 0, 0), seg=8)


# ================= Sitting =================
def rocking_chair():
	ys = [-0.45 + 0.9 * i / 12 for i in range(13)]
	for x in (-0.24, 0.24):
		bar([(y, 0.025 + 0.16 * (y / 0.45) ** 2) for y in ys], 0.05, 0.05, T("wood", "dark"), x)
		for y in (-0.2, 0.2):
			B((0.055, 0.055, 0.4), (x, y, 0.26), WOOD(), bevel=0.01)
		B((0.055, 0.055, 0.62), (x, 0.23, 0.76), WOOD(), bevel=0.01, rot=(-8, 0, 0))
		B((0.07, 0.5, 0.04), (x * 1.21, 0.0, 0.66), T("wood", "b"), bevel=0.01)
		B((0.04, 0.04, 0.2), (x * 1.21, -0.2, 0.56), WOOD(), bevel=0.006)
	B((0.56, 0.5, 0.05), (0, 0, 0.47), T("wood", "b"), bevel=0.012)
	cushion((0, -0.02, 0.52), (0.46, 0.42, 0.06), (0.32, 0.1, 0.06))
	for x in (-0.12, 0.0, 0.12):
		B((0.06, 0.03, 0.46), (x, 0.245, 0.78), WOOD(), bevel=0.006, rot=(-8, 0, 0))
	B((0.5, 0.04, 0.05), (0, 0.23, 0.56), WOOD(), bevel=0.006, rot=(-8, 0, 0))
	B((0.6, 0.06, 0.1), (0, 0.272, 1.03), T("wood", "b"), bevel=0.015, rot=(-8, 0, 0))
	# a knitted throw over the back rail
	mesh_cloth((0.08, 0.24), 1.085, 0.3, 0.35, m=C((0.3, 0.42, 0.25), 0.95))


# ================= Bedroom =================
def fur_rug():
	"""A woven wool rug (owner Nov 21: crisp parts, no fur blob): leather border with stitching, diamond pattern, fringe."""
	L, Wd = 1.6, 1.0
	B((L, Wd, 0.012), (0, 0, 0.006), kit.tex_mat("rugcloth", "b"), bevel=0.003)
	# tooled leather border, stitched along both edges
	bw = 0.07
	for s_ in (-1, 1):
		B((L, bw, 0.012), (0, s_ * (Wd / 2 - bw / 2), 0.016), kit.tex_mat("leather", "dark"), bevel=0.004)
		B((bw, Wd - 2 * bw - 0.004, 0.012), (s_ * (L / 2 - bw / 2), 0, 0.016), kit.tex_mat("leather", "dark"), bevel=0.004)
	stitch = C((0.78, 0.66, 0.42), 0.9)
	for s_ in (-1, 1):
		for edge in (0.012, bw - 0.012):
			y = s_ * (Wd / 2 - edge)
			for k in range(int((L - 0.06) / 0.05)):
				B((0.026, 0.005, 0.004), (-L / 2 + 0.045 + k * 0.05, y, 0.0225), stitch, bevel=0)
			x = s_ * (L / 2 - edge)
			for k in range(int((Wd - 2 * bw) / 0.05)):
				B((0.005, 0.026, 0.004), (x, -Wd / 2 + bw + 0.03 + k * 0.05, 0.0225), stitch, bevel=0)
	# inner band of darker weave, then the pattern field
	red, ochre, cream, dark = kit.tex_mat("rugcloth", "a"), C((0.42, 0.26, 0.1), 0.95), C((0.6, 0.5, 0.34), 0.95), kit.tex_mat("rugcloth", "dark")
	fl, fw = L - 2 * bw - 0.06, Wd - 2 * bw - 0.06
	for s_ in (-1, 1):
		B((fl, 0.035, 0.008), (0, s_ * (fw / 2 - 0.0175), 0.014), dark, bevel=0.002)
		B((0.035, fw - 0.08, 0.008), (s_ * (fl / 2 - 0.0175), 0, 0.014), dark, bevel=0.002)
	# a big centre diamond with a small cream diamond inside, half diamonds and a chevron row toward each end
	B((0.34, 0.34, 0.008), (0, 0, 0.014), red, bevel=0.002, rot=(0, 0, 45))
	B((0.2, 0.2, 0.006), (0, 0, 0.019), ochre, bevel=0.002, rot=(0, 0, 45))
	B((0.08, 0.08, 0.004), (0, 0, 0.0235), cream, bevel=0.001, rot=(0, 0, 45))
	for s_ in (-1, 1):
		for k in range(3):
			x = s_ * (0.42 + k * 0.1)
			B((0.06, 0.06, 0.008), (x, 0, 0.014), red if k % 2 else ochre, bevel=0.002, rot=(0, 0, 45))
		for k in range(5):
			y = -0.22 + k * 0.11
			for j, dx in enumerate((-0.028, 0.028)):
				B((0.07, 0.022, 0.008), (s_ * 0.31 + dx, y, 0.014 + 0.002 * j), cream, bevel=0.002, rot=(0, 0, (45 if j else -45) * s_))
	for s_ in (-1, 1):  # four corner squares
		for t_ in (-1, 1):
			B((0.07, 0.07, 0.008), (s_ * (fl / 2 - 0.08), t_ * (fw / 2 - 0.08), 0.014), ochre, bevel=0.002)
	# fringe: knotted tassels on both short ends
	wool = C((0.62, 0.5, 0.32), 0.95)
	for s_ in (-1, 1):
		for k in range(16):
			y = -Wd / 2 + 0.06 + k * (Wd - 0.12) / 15
			x0 = s_ * (L / 2 - 0.005)
			kit.cylinder(0.009, 0.02, (x0 + s_ * 0.012, y, 0.008), wool, rot=(0, 90, 0), verts=6, bevel=0.002)
			for d in (-0.008, 0.008):
				B((0.07, 0.006, 0.006), (x0 + s_ * 0.055, y + d, 0.004), wool, bevel=0.001, rot=(0, 0, s_ * d * 300))


def hammock():
	"""Rope-net hammock between two lashed posts (owner Nov 21: no red cloth, real net weave, rings at the ends)."""
	for x in (-1.05, 1.05):
		s_ = 1 if x > 0 else -1
		stone((0.32, 0.32, 0.14), (x, 0, 0.07))
		log((x, 0, 0.1), (x, 0, 1.35), 0.07, T("bark"), seg=8, rings=3, bend=0.04)
		for y in (-0.38, 0.38):  # side braces with their own footing stones, lashed to the post
			stone((0.16, 0.16, 0.1), (x + s_ * 0.05, y, 0.05))
			log((x + s_ * 0.05, y, 0.06), (x, y * 0.12, 0.8), 0.04, T("bark"), seg=7, rings=2)
		rope_tie((x, 0, 0.8), 0.07)
		rope_tie((x, 0, 1.2), 0.07)
		kit.cylinder(0.075, 0.05, (x, 0, 1.37), T("wood", "c"), verts=10, bevel=0.01)
		# iron ring tied to the post, all the net strings gather into it
		rx = x - s_ * 0.13
		kit.ring(0.045, 0.012, (rx, 0, 1.14), IRON("dark"), rot=(90, 0, 0), seg=14)
		kit.rope((x - s_ * 0.06, 0, 1.18), (rx + s_ * 0.04, 0, 1.15), r=0.014)
		# spreader bar with one hole per string (pegs show where they pass)
		bx = s_ * 0.77
		log((bx, -0.38, 0.88), (bx, 0.38, 0.88), 0.028, T("wood", "c"), seg=7, rings=1)
		for k in range(7):
			y = -0.3 + k * 0.1
			kit.rope((bx, y, 0.9), (rx - s_ * 0.005, 0, 1.11), r=0.007)
			kit.ring(0.031, 0.006, (bx, y, 0.88), kit.tex_mat("rope"), rot=(0, 90, 0), seg=10)

	def f(u, v):
		x, y = -0.76 + 1.52 * u, -0.3 + 0.6 * v
		return (x, y, 0.52 + 0.36 * (x / 0.76) ** 2 + 0.06 * (y / 0.3) ** 2)
	twine = kit.tex_mat("rope", "b")
	nu, nv = 16, 6
	for j in range(nv + 1):  # lengthwise strings
		pts = [f(i / nu, j / nv) for i in range(nu + 1)]
		pts[0] = (pts[0][0] - 0.0, pts[0][1], 0.88)
		pts[-1] = (pts[-1][0], pts[-1][1], 0.88)
		for p, q in zip(pts, pts[1:]):
			log(p, q, 0.008 if 0 < j < nv else 0.013, twine, seg=5, rings=1, ends=False, bend=0)
	for i in range(1, nu):  # cross strings, knotted where they meet the lengthwise ones
		pts = [f(i / nu, j / nv) for j in range(nv + 1)]
		pts = [(p[0], p[1], p[2] - 0.004) for p in pts]
		for p, q in zip(pts, pts[1:]):
			log(p, q, 0.007, twine, seg=5, rings=1, ends=False, bend=0)
		for p in pts[1:-1:2]:
			sphere(p, 0.012, kit.tex_mat("rope", "b"), seg=6, rings=4)


def bunk_bed():
	"""Bare wooden bunks (owner Nov 21: no pillows or covers): slats on ledgers, spindle ends, pegged joints, ladder."""
	W, D, H = 1.9, 0.95, 1.6
	wood = lambda: T("wood", rng.choice("ab"))  # noqa: E731
	peg = kit.tex_mat("wood", "c")
	xs, ys = (-W / 2 + 0.045, W / 2 - 0.045), (-D / 2 + 0.045, D / 2 - 0.045)
	for x in xs:
		for y in ys:
			B((0.09, 0.09, H), (x, y, H / 2), wood(), bevel=0.015)
			kit.cone(0.05, 0.03, 0.06, (x, y, H + 0.025), wood(), verts=8, bevel=0.006)
	for z0 in (0.22, 0.95):
		for y in ys:  # long side rails, a ledger strip inside each one carries the slats
			B((W - 0.08, 0.06, 0.14), (0, y, z0), wood(), bevel=0.01)
			B((W - 0.1, 0.035, 0.04), (0, y - math.copysign(0.045, y), z0 - 0.03), T("wood", "dark"), bevel=0.006)
			for x in xs:
				for dz in (-0.035, 0.035):
					rivet((x - math.copysign(0.07, x), y - math.copysign(0.031, y) * -1, z0 + dz), peg, r=0.012)
		for x in xs:  # end rails
			B((0.06, D - 0.08, 0.14), (x, 0, z0), wood(), bevel=0.01)
		n = 11
		for i in range(n):  # slats with a small gap between each
			x = -W / 2 + 0.14 + i * (W - 0.28) / (n - 1)
			plank((0.11, D - 0.13, 0.025), (x, 0, z0 - 0.0), m=wood())
			for y in (-D / 2 + 0.1, D / 2 - 0.1):
				rivet((x, y, z0 + 0.012), IRON("dark"), r=0.008)
	for x in xs:  # head and foot ends: top rail and spindles between the bunks and above the top bunk
		for (za, zb) in ((0.285, 0.89), (1.015, 1.45)):
			if zb > 1:
				B((0.05, D - 0.08, 0.06), (x, 0, zb + 0.03), wood(), bevel=0.008)
			for k in range(4):
				y = -D / 2 + 0.19 + k * (D - 0.38) / 3
				B((0.035, 0.035, zb - za + 0.01), (x, y, (za + zb) / 2), wood(), bevel=0.006)
	# top guard rail at the front (open where the ladder comes up)
	B((1.14, 0.05, 0.1), (-0.38, -D / 2 + 0.045, 1.25), wood(), bevel=0.01)
	B((0.06, 0.06, 0.3), (0.17, -D / 2 + 0.045, 1.13), wood(), bevel=0.008)
	for x in (-0.5, -0.1):
		B((0.035, 0.035, 0.18), (x, -D / 2 + 0.045, 1.11), wood(), bevel=0.005)
	# ladder hooked on the top rail
	for x in (0.45, 0.75):
		B((0.05, 0.05, 1.36), (x, -D / 2 - 0.02, 0.68), wood(), bevel=0.008)
		B((0.05, 0.06, 0.05), (x, -D / 2 + 0.01, 1.32), T("wood", "dark"), bevel=0.006)
	for z in (0.35, 0.65, 1.15):
		log((0.45, -D / 2 - 0.02, z), (0.75, -D / 2 - 0.02, z), 0.022, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)


def wardrobe():
	"""A tall two-door wardrobe in one wood family (owner Nov 21: the woods didn't match)."""
	W, D, H = 1.0, 0.55, 1.7
	main, trim = kit.tex_mat("wood", "b"), kit.tex_mat("wood", "a")
	for x in (-0.42, 0.42):
		for y in (-0.2, 0.2):
			kit.cone(0.06, 0.045, 0.12, (x, y, 0.06), trim, verts=8, bevel=0.01)
	B((W, D, H - 0.1), (0, 0, 0.1 + (H - 0.1) / 2), main, bevel=0.015)
	B((W + 0.08, D + 0.06, 0.08), (0, 0, H + 0.02), trim, bevel=0.015)
	B((W + 0.02, D + 0.02, 0.04), (0, 0, H - 0.035), main, bevel=0.01)
	B((W + 0.04, D + 0.03, 0.06), (0, 0, 0.135), trim, bevel=0.012)
	for s_ in (-1, 1):
		x = s_ * 0.235
		B((0.46, 0.03, 1.4), (x, -D / 2 - 0.005, 0.88), main, bevel=0.01)
		for z in (0.55, 1.2):  # raised panels with a frame
			B((0.32, 0.016, 0.55), (x, -0.297, z), trim, bevel=0.008)
			B((0.24, 0.012, 0.45), (x, -0.31, z), main, bevel=0.006)
		for z in (0.4, 1.35):
			B((0.1, 0.026, 0.04), (s_ * 0.45, -0.302, z), IRON("dark"), bevel=0.004)
			rivet((s_ * 0.42, -0.316, z), IRON())
		kit.ring(0.03, 0.008, (s_ * 0.04, -0.3, 0.9), IRON(), rot=(90, 0, 0), seg=10)
		rivet((s_ * 0.04, -0.296, 0.93), IRON())
	B((0.012, 0.02, 1.36), (0, -0.3, 0.88), trim, bevel=0.003)


# ================= Washroom =================
def bathtub_barrel():
	"""Half-barrel bathtub, empty (owner Nov 21), with a bare stool beside it."""
	R, H, n = 0.5, 0.55, 18
	for k in range(n):
		a = 2 * math.pi * k / n
		B((2 * math.pi * R / n * 1.05, 0.05, H + J(0.02)), (math.cos(a) * (R - 0.025), math.sin(a) * (R - 0.025), H / 2), WOOD(), bevel=0.008,
			rot=(0, 0, math.degrees(a) + 90))
	for i in range(5):  # floor boards inside
		y = -0.36 + i * 0.18
		half = math.sqrt(max(0.0, (R - 0.04) ** 2 - y ** 2))
		B((2 * half, 0.17, 0.04), (0, y, 0.06), T("wood", "dark"), bevel=0.006)
	kit.cylinder(0.035, 0.012, (0.1, -0.05, 0.085), T("wood", "c"), verts=10, bevel=0.003)  # drain bung
	for z in (0.1, 0.45):
		kit.ring(R + 0.006, 0.016, (0, 0, z), IRON("dark"), seg=28)
		for k in range(6):
			a = 2 * math.pi * (k + 0.5) / 6
			rivet((math.cos(a) * (R + 0.02), math.sin(a) * (R + 0.02), z), IRON(), r=0.01)
	for s_ in (-1, 1):  # two carry cleats
		B((0.06, 0.12, 0.05), (s_ * (R + 0.02), 0, 0.5), T("wood", "c"), bevel=0.01)
	# bare stool beside it
	kit.cylinder(0.16, 0.06, (0.8, -0.05, 0.33), T("wood", "b"), verts=12, bevel=0.01)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.4
		log((0.8 + math.cos(a) * 0.07, -0.05 + math.sin(a) * 0.07, 0.31), (0.8 + math.cos(a) * 0.14, -0.05 + math.sin(a) * 0.14, 0.0), 0.03, T("wood", "c"), seg=6, rings=1)
	kit.ring(0.1, 0.01, (0.8, -0.05, 0.15), kit.tex_mat("rope"), seg=14)


def washbasin():
	"""Wash stand with an empty clay basin and jug (owner Nov 21: empty)."""
	legs4(0.5, 0.4, 0.72, r=0.03, logs=False, m=T("wood", "dark"))
	B((0.56, 0.44, 0.05), (0, 0, 0.735), T("wood", "b"), bevel=0.012)
	plank((0.46, 0.34, 0.03), (0, 0, 0.2))
	bx, by = -0.07, 0.03
	lathe([(0, 0.76), (0.13, 0.76), (0.19, 0.84), (0.17, 0.84), (0.115, 0.78), (0, 0.78)], (bx, by), kit.tex_mat("clay", "b"))  # hollow, empty
	kit.ring(0.185, 0.02, (bx, by, 0.845), kit.tex_mat("clay", "a"), seg=20)
	jx, jy = 0.19, -0.1
	kit.cylinder(0.06, 0.16, (jx, jy, 0.84), kit.tex_mat("clay", "c"), verts=12, bevel=0.01)
	kit.cone(0.06, 0.04, 0.06, (jx, jy, 0.945), kit.tex_mat("clay", "c"), verts=12, bevel=0.005)
	kit.ring(0.042, 0.01, (jx, jy, 0.975), kit.tex_mat("clay", "a"), seg=12)
	kit.ring(0.045, 0.012, (jx + 0.065, jy, 0.86), kit.tex_mat("clay", "c"), rot=(90, 0, 0), seg=10)
	# empty towel rail at the front
	for x in (-0.2, 0.2):
		B((0.03, 0.06, 0.03), (x, -0.235, 0.69), T("wood", "dark"), bevel=0.004)
	log((-0.22, -0.26, 0.69), (0.22, -0.26, 0.69), 0.013, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.11, 0.14, (0.05, 0.0, 0.285), kit.tex_mat("clay", "a"), verts=12, bevel=0.01)
	kit.ring(0.105, 0.012, (0.05, 0.0, 0.355), kit.tex_mat("clay", "b"), seg=14)


def boot_rack():
	"""Two-shelf boot rack, empty (owner Nov 21), with pegs along the back rail."""
	for x in (-0.4, 0.4):
		B((0.04, 0.3, 0.44), (x, 0, 0.22), T("wood", "dark"), bevel=0.008)
		for z in (0.06, 0.4):
			rivet((x - math.copysign(0.021, x) * -1, -0.1, z), kit.tex_mat("wood", "c"), r=0.012)
	plank((0.78, 0.28, 0.03), (0, 0, 0.06))
	plank((0.78, 0.28, 0.03), (0, 0, 0.4))
	B((0.8, 0.03, 0.06), (0, 0.13, 0.25), T("wood", "dark"), bevel=0.006)
	for z in (0.085, 0.425):  # low lips so boots don't slide off
		B((0.76, 0.02, 0.025), (0, -0.125, z), T("wood", "dark"), bevel=0.004)
	for x in (-0.3, -0.1, 0.1, 0.3):
		log((x, 0.115, 0.25), (x, 0.04, 0.29), 0.012, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)


# ================= Study =================
def writing_desk():
	W, D, H = 1.1, 0.6, 0.7
	legs4(W, D, H - 0.05, r=0.035, m=T("wood", "dark"), logs=False)
	B((W - 0.1, D - 0.1, 0.12), (0, 0, 0.57), T("wood", "dark"), bevel=0.01)
	plank_top(W + 0.04, D + 0.04, H - 0.03, n=3)
	B((0.36, 0.03, 0.09), (0.25, -0.26, 0.57), T("wood", "b"), bevel=0.008)
	rivet((0.25, -0.28, 0.57), CU(), r=0.02)
	# pigeon-hole riser at the back with scrolls
	B((W - 0.04, 0.03, 0.3), (0, 0.27, 0.855), T("wood", "b"), bevel=0.006)
	for x in (-0.52, -0.17, 0.17, 0.52):
		B((0.03, 0.14, 0.3), (x, 0.22, 0.85), T("wood", "b"), bevel=0.006)
	B((W, 0.16, 0.03), (0, 0.22, 1.0), T("wood", "dark"), bevel=0.008)
	for (x, z, rot) in ((-0.345, 0.74, (0, 90, 0)), (-0.33, 0.805, (0, 90, 0)), (0.345, 0.74, (0, 90, 0)), (0.0, 0.74, (90, 0, 0))):
		kit.cylinder(0.035, 0.2, (x, 0.2, z), C((0.86, 0.78, 0.6), 0.9), rot=rot, verts=10, bevel=0.004)
	# papers, ink pot and quill
	B((0.3, 0.22, 0.004), (-0.15, -0.05, 0.703), C((0.88, 0.82, 0.66), 0.95), bevel=0, rot=(0, 0, 8))
	B((0.28, 0.2, 0.004), (-0.12, -0.03, 0.709), C((0.92, 0.86, 0.7), 0.95), bevel=0, rot=(0, 0, -6))
	for k in range(4):
		B((0.18, 0.006, 0.003), (-0.12, -0.08 + k * 0.04, 0.7115), C((0.35, 0.25, 0.15), 0.9), bevel=0, rot=(0, 0, -6))
	kit.cylinder(0.04, 0.06, (0.3, 0.05, 0.73), C((0.14, 0.13, 0.16), 0.35), verts=12, bevel=0.008)
	kit.cylinder(0.022, 0.02, (0.3, 0.05, 0.765), C((0.14, 0.13, 0.16), 0.35), verts=10, bevel=0.003)
	log((0.3, 0.05, 0.745), (0.387, 0.05, 1.0), 0.005, C((0.92, 0.9, 0.84), 0.8), seg=5, rings=1, ends=False, bend=0)
	kit.cone(0.035, 0.006, 0.18, (0.36, 0.05, 0.915), C((0.92, 0.9, 0.84), 0.8), rot=(0, 18, 0), verts=8, bevel=0).scale = (1, 0.25, 1)
	kit.cylinder(0.035, 0.1, (-0.42, -0.15, 0.75), C((0.95, 0.9, 0.75), 0.8), verts=8, bevel=0.004)
	kit.cylinder(0.06, 0.015, (-0.42, -0.15, 0.705), CU(), verts=12, bevel=0.003)
	kit.fire_spot((-0.42, -0.15, 0.82), 0.1)


def world_stone():
	kit.cylinder(0.28, 0.06, (0, 0, 0.03), T("wood", "dark"), verts=16, bevel=0.012)
	log((0, 0, 0.05), (0, 0, 0.33), 0.05, T("wood", "b"), seg=8, rings=2, bend=0.02)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		log((math.cos(a) * 0.15, math.sin(a) * 0.15, 0.05), (math.cos(a) * 0.33, math.sin(a) * 0.33, 0.62), 0.03, T("wood", "b"), seg=7, rings=2)
	kit.ring(0.33, 0.035, (0, 0, 0.62), T("wood", "c"), seg=28)
	c, r = Vector((0, 0, 0.62)), 0.32
	sphere(tuple(c), r, T("limestone", "b"), seg=20, rings=12)
	kit.ring(0.36, 0.015, tuple(c), CU(), rot=(90, 0, 0), seg=30)
	kit.cylinder(0.02, 0.06, (0, 0, 0.99), CU(), verts=8, bevel=0.003)
	groove = C((0.1, 0.08, 0.07), 0.8)
	R = random.Random(9)
	for t in range(6):
		d = Vector((R.uniform(-1, 1), R.uniform(-1, 1), R.uniform(-0.6, 0.8))).normalized()
		tan = d.orthogonal().normalized()
		pts = []
		for i in range(9):
			pts.append(c + d * (r + 0.002))
			d = (d + tan * 0.22).normalized()
			tan = (tan - d * tan.dot(d)).normalized()
			tan = (tan + d.cross(tan) * R.uniform(-0.5, 0.5)).normalized()
			tan = (tan - d * tan.dot(d)).normalized()
		for p, q in zip(pts, pts[1:]):
			log(tuple(p), tuple(q), 0.015, groove, seg=6, rings=1, ends=False, bend=0)
		e = pts[-1] - c
		kit.gem(tuple(c + e.normalized() * (r + 0.004)), (0.03, 0.03, 0.03), groove, seed=t)
	kit.gem(tuple(c + Vector((0.1, -0.9, 0.3)).normalized() * (r + 0.006)), (0.022, 0.022, 0.022), C((1.0, 0.6, 0.2), 0.3, glow=1.5), seed=4)


# ================= Storage =================
def storage_trunk():
	"""An old trunk, broken and empty (owner Nov 21): lid torn half off and hanging down the back, a split front plank."""
	W, D, H = 1.0, 0.55, 0.45
	dark = T("wood", "dark")
	B((W - 0.04, D - 0.04, 0.04), (0, 0, 0.03), T("wood", "b"), bevel=0.006)  # bottom
	for i in range(3):  # inside floor boards
		plank((W - 0.1, (D - 0.1) / 3 - 0.01, 0.02), (0, -(D - 0.1) / 3 + i * (D - 0.1) / 3, 0.06))
	ph = H / 3
	for k in range(3):
		z = ph * (k + 0.5)
		for s_ in (-1, 1):
			if not (s_ < 0 and k == 1):
				plank((W, 0.035, ph - 0.008), (0, s_ * (D / 2 - 0.0175), z))
			plank((0.035, D - 0.07, ph - 0.008), (s_ * (W / 2 - 0.0175), 0, z))
	# the split middle front plank: two pieces with a jagged gap, one splinter bent outward
	z = ph * 1.5
	plank((0.46, 0.035, ph - 0.008), (-0.27, -D / 2 + 0.0175, z))
	plank((0.36, 0.035, ph - 0.008), (0.32, -D / 2 + 0.0175, z))
	for k, (x, dz, s) in enumerate(((-0.025, 0.03, 1), (-0.035, -0.02, 1), (0.135, 0.01, -1), (0.14, -0.035, -1))):
		kit.cone(0.018, 0.0, 0.06, (x + s * 0.02, -D / 2 + 0.0175, z + dz), T("wood", "c"), rot=(0, s * 90, 0), verts=4, bevel=0)
	B((0.16, 0.025, 0.05), (0.05, -D / 2 - 0.03, 0.013), T("wood", "b"), bevel=0.006, rot=(0, 0, 25))  # broken-off piece on the floor
	for cx in (-1, 1):  # iron corner straps
		for cy in (-1, 1):
			B((0.07, 0.012, H - 0.01), (cx * (W / 2 - 0.035), cy * (D / 2 + 0.006), H / 2), IRON("dark"), bevel=0.003)
			B((0.012, 0.07, H - 0.01), (cx * (W / 2 + 0.006), cy * (D / 2 - 0.035), H / 2), IRON("dark"), bevel=0.003)
	for x in (-0.3, 0.3):
		for s_ in (-1, 1):
			B((0.07, 0.016, H - 0.02), (x, s_ * (D / 2 + 0.008), H / 2), IRON(), bevel=0.004)
			for zz in (0.08, 0.22, 0.36):
				rivet((x, s_ * (D / 2 + 0.017), zz), IRON("dark"), r=0.011)
	for s_ in (-1, 1):
		kit.ring(0.06, 0.012, (s_ * (W / 2 + 0.01), 0, 0.29), IRON(), rot=(0, 90, 0), seg=12)
		B((0.02, 0.1, 0.04), (s_ * (W / 2 + 0.005), 0, 0.34), IRON("dark"), bevel=0.004)
	B((0.12, 0.025, 0.12), (0, -D / 2 - 0.006, H - 0.07), CU(), bevel=0.008)  # empty lock plate, hasp hangs loose
	B((0.05, 0.012, 0.1), (0.0, -D / 2 - 0.022, H - 0.13), IRON("dark"), bevel=0.003, rot=(0, 18, 0))

	def lid():  # built with its hinge edge on the origin, running toward -Y
		for i in range(4):
			plank((W - 0.02, (D + 0.02) / 4 - 0.008, 0.04), (0, -(D + 0.02) / 8 - i * (D + 0.02) / 4, 0.02))
		for x in (-0.3, 0.3):
			B((0.07, D + 0.03, 0.02), (x, -(D + 0.02) / 2, 0.048), IRON(), bevel=0.004)
		B((0.08, 0.1, 0.012), (-0.3, -0.03, 0.06), IRON("dark"), bevel=0.003)
	group(lid, at=(0, D / 2 + 0.035, H + 0.01), rot=(-228, 3, 0))
	for x in (-0.3, 0.3):  # bent hinge straps joining lid and back
		B((0.06, 0.05, 0.05), (x, D / 2 + 0.02, H - 0.005), IRON("dark"), bevel=0.005)


# ================= Tavern =================
def bar_counter():
	L = 2.0
	B((L - 0.06, 0.5, 0.88), (0, 0.02, 0.44), T("wood", "dark"), bevel=0.01)
	for i in range(5):
		B((0.06, 0.05, 0.84), (-0.96 + i * 0.48, -0.25, 0.43), T("wood", "b"), bevel=0.008)
	for z in (0.06, 0.8):
		B((L - 0.04, 0.04, 0.08), (0, -0.25, z), T("wood", "b"), bevel=0.008)
	for i in range(4):
		B((0.42, 0.02, 0.62), (-0.72 + i * 0.48, -0.245, 0.43), WOOD(), bevel=0.006)
		rivet((-0.72 + i * 0.48, -0.258, 0.43), CU("dark"), r=0.02)
	plank_top(L + 0.06, 0.7, 0.9, n=3)
	for x in (-0.7, 0.0, 0.7):
		B((0.03, 0.12, 0.03), (x, -0.32, 0.15), CU("dark"), bevel=0.004)
	log((-0.95, -0.38, 0.15), (0.95, -0.38, 0.15), 0.02, CU(), seg=8, rings=1, ends=False, bend=0)
	mug(-0.5, -0.1, 0.932)
	mug(-0.3, 0.05, 0.932, kit.tex_mat("clay", "a"))
	B((0.3, 0.18, 0.02), (0.55, 0.0, 0.94), C(LINEN, 0.95), bevel=0.006, rot=(0, 0, 12))


def tap_keg_stand():
	"""Keg on a cradle stand with a plain copper tap (owner Nov 21: removed the bug-looking bits)."""
	legs4(0.6, 0.7, 0.42, r=0.04, logs=False, m=T("wood", "dark"))
	plank_top(0.7, 0.86, 0.45, n=3, along="y")
	for y in (-0.22, 0.22):
		B((0.5, 0.08, 0.06), (0, y, 0.51), T("wood", "dark"), bevel=0.01)
		for x in (-0.18, 0.18):
			B((0.08, 0.07, 0.22), (x, y, 0.62), T("wood", "dark"), bevel=0.01, rot=(0, -math.copysign(30, x), 0))
	z = 0.98
	o = kit.cylinder(0.3, 0.7, (0, 0, z), T("wood", "b"), rot=(90, 0, 0), verts=16, bevel=0.03)
	o.scale = (1.08, 1.08, 1)
	for y in (-0.28, -0.1, 0.1, 0.28):
		kit.ring(0.31 if abs(y) < 0.2 else 0.3, 0.02, (0, y, z), CU(), rot=(90, 0, 0), seg=20)
	kit.cylinder(0.04, 0.03, (0, 0, z + 0.33), T("wood", "c"), verts=8, bevel=0.004)
	# copper tap: a flange on the keg end, a straight pipe, a down spout and a flat key on top
	kit.cylinder(0.05, 0.02, (0, -0.355, 0.84), CU("dark"), rot=(90, 0, 0), verts=12, bevel=0.004)
	kit.cylinder(0.022, 0.12, (0, -0.42, 0.84), CU(), rot=(90, 0, 0), verts=10, bevel=0.004)
	kit.cylinder(0.02, 0.07, (0, -0.47, 0.81), CU(), verts=10, bevel=0.004)
	kit.cylinder(0.012, 0.05, (0, -0.43, 0.88), CU("dark"), verts=8, bevel=0.002)
	B((0.08, 0.016, 0.03), (0, -0.43, 0.91), CU(), bevel=0.004)
	B((0.2, 0.16, 0.04), (0, -0.4, 0.5), CU("dark"), bevel=0.006)  # drip tray with a grate
	for k in range(4):
		B((0.17, 0.012, 0.012), (0, -0.45 + k * 0.033, 0.524), IRON("dark"), bevel=0)


def mug_rack():
	floor_post(1.06)
	B((0.9, 0.06, 0.3), (0, 0.03, 1.2), T("wood", "b"), bevel=0.012)
	plank((0.92, 0.18, 0.04), (0, -0.06, 1.365))
	for x in (-0.38, 0.38):
		B((0.04, 0.1, 0.1), (x, -0.04, 1.3), T("wood", "dark"), bevel=0.006)
	for i, x in enumerate((-0.32, -0.16, 0.0, 0.16, 0.32)):
		log((x, 0.0, 1.12), (x, -0.13, 1.165), 0.015, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
		m = [T("wood", "c"), kit.tex_mat("clay", "a"), CU("a"), kit.tex_mat("clay", "b"), T("wood", "b")][i]
		kit.ring(0.045, 0.009, (x, -0.1, 1.1), m, rot=(90, 0, 0), seg=10)
		kit.cylinder(0.05, 0.12, (x, -0.1, 1.01), m, verts=10, bevel=0.008)
		kit.ring(0.051, 0.007, (x, -0.1, 0.98), IRON(), seg=12)
	for x in (-0.25, 0.05, 0.28):
		mug(x, -0.07, 1.385)


# ================= Kitchen =================
def bread_oven():
	"""Clay bread oven on a stone base (owner Nov 21: 9/10, bread removed)."""
	stone_blocks(1.1, 1.0, 0.5)
	B((1.14, 1.04, 0.06), (0, 0, 0.53), T("stone", "c"), bevel=0.015)
	sphere((0, 0.05, 0.555), 0.45, kit.tex_mat("clay", "b"), scale=(1, 1, 0.95), seg=18, rings=10, cut=0.0)
	kit.ring(0.45, 0.03, (0, 0.05, 0.58), T("brick"), seg=24)
	B((0.5, 0.3, 0.36), (0, -0.32, 0.74), T("brick"), bevel=0.012)
	kit.cylinder(0.24, 0.28, (0, -0.32, 0.92), T("brick"), rot=(90, 0, 0), verts=14, bevel=0.01)
	for i in range(7):
		a = math.pi * (i + 0.5) / 7
		B((0.08, 0.04, 0.07), (-math.cos(a) * 0.21, -0.475, 0.78 + math.sin(a) * 0.21), T("limestone"), bevel=0.004, rot=(0, math.degrees(a - math.pi / 2), 0))
	for x in (-0.21, 0.21):
		B((0.07, 0.04, 0.16), (x, -0.475, 0.69), T("limestone"), bevel=0.004)
	B((0.3, 0.04, 0.16), (0, -0.48, 0.7), T("wood", "dark"), bevel=0.006)
	kit.cylinder(0.15, 0.03, (0, -0.48, 0.78), T("wood", "dark"), rot=(90, 0, 0), verts=14, bevel=0.004)
	B((0.32, 0.01, 0.03), (0, -0.505, 0.72), IRON("dark"), bevel=0.002)
	kit.ring(0.03, 0.008, (0, -0.51, 0.8), IRON(), rot=(90, 0, 0), seg=10)
	B((0.2, 0.012, 0.02), (0, -0.476, 0.6), C((1.0, 0.45, 0.12), 0.3, glow=2.0), bevel=0)
	kit.cylinder(0.08, 0.3, (0, 0.25, 1.0), T("brick"), verts=10, bevel=0.008)
	kit.ring(0.085, 0.015, (0, 0.25, 1.15), T("limestone"), seg=12)
	# bread peel leaning on the base
	B((0.03, 0.28, 0.32), (0.585, -0.2, 0.17), T("wood", "c"), bevel=0.01, rot=(0, -8, 0))
	log((0.6, -0.2, 0.32), (0.52, -0.2, 1.15), 0.02, T("wood", "c"), seg=6, rings=2, bend=0.02)


def cooking_spit():
	"""Roasting spit over a stone fire ring: forked posts lashed with rope, iron crank, spit forks, firewood, poker."""
	disc(0.36, 0.004, 0.02, (0, 0), kit.mat("charcoal", 0.1), seg=16, wob=0.06)
	for k in range(12):
		a = 2 * math.pi * k / 12
		stone((0.16 + 0.04 * (k % 2), 0.13, 0.12 + 0.04 * (k % 3 == 0)), (math.cos(a) * 0.41, math.sin(a) * 0.41, 0.07), rotz=math.degrees(a) + 90)
	for k in range(12):  # embers on a spiral, so no two overlap
		a, d = k * 2.4, 0.24 * math.sqrt((k + 0.5) / 12)
		kit.gem((math.cos(a) * d, math.sin(a) * d, 0.035), (0.055, 0.05, 0.03), kit.glow("ember", 1.0) if k % 3 == 0 else kit.mat("charcoal", 0.1 * (k % 4) - 0.1), seed=k + 11)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.5
		log((math.cos(a) * 0.27, math.sin(a) * 0.27, 0.04), (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.24), 0.045, T("bark"), seg=7, rings=2)
	kit.fire_spot((0, 0, 0.14), 0.6)
	for x in (-0.6, 0.6):
		stone((0.18, 0.18, 0.1), (x, 0, 0.05))
		log((x, 0, 0.0), (x, 0, 0.68), 0.04, T("bark"), seg=7, rings=2, bend=0.03)
		for s_ in (-1, 1):
			log((x, s_ * 0.012, 0.64), (x, s_ * 0.08, 0.82), 0.025, T("bark"), seg=6, rings=1)
		rope_tie((x, 0, 0.6), 0.042)
		kit.ring(0.022, 0.008, (x, 0, 0.74), IRON("dark"), rot=(0, 90, 0), seg=10)  # iron collar where the spit turns
	log((-0.74, 0, 0.74), (0.7, 0, 0.74), 0.015, IRON(), seg=6, rings=1, ends=False, bend=0)
	kit.ring(0.02, 0.006, (0.7, 0, 0.74), IRON("dark"), rot=(0, 90, 0), seg=8)
	# crank: arm down from the spit end and a turned wooden handle
	B((0.02, 0.03, 0.17), (-0.74, 0, 0.67), IRON("dark"), bevel=0.004)
	log((-0.74, 0, 0.6), (-0.86, 0, 0.6), 0.02, T("wood", "c"), seg=6, rings=1)
	rivet((-0.74, -0.016, 0.6), IRON(), r=0.01)
	# the roast held between two iron spit forks
	o = sphere((0, 0, 0.74), 0.14, C((0.22, 0.09, 0.035), 0.5), scale=(1.5, 1, 0.9), seg=18, rings=10)
	kit.roughen(o, 0.006, 1, seed=3)
	for s_ in (-1, 1):
		kit.ring(0.078, 0.009, (s_ * 0.17, 0, 0.74), kit.tex_mat("rope"), rot=(0, 90, 0), seg=12)
		x = s_ * 0.24
		B((0.025, 0.12, 0.03), (x, 0, 0.74), IRON("dark"), bevel=0.004)
		for y in (-0.05, 0.05):
			log((x, y, 0.74), (x - s_ * 0.06, y, 0.74), 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
	# firewood stack beside the ring, a poker leaning on a post
	for i, (y, z) in enumerate(((-0.12, 0.042), (0.0, 0.042), (0.12, 0.042), (-0.06, 0.104), (0.06, 0.104))):
		log((0.78, y, z), (1.12, y + J(0.01), z), 0.045, T("bark"), seg=7, rings=2, end_m=kit.tex_mat("wood", "c"))
	log((0.86, -0.16, 0.0), (0.61, -0.035, 0.5), 0.009, IRON("dark"), seg=5, rings=2, ends=False, bend=0)
	kit.ring(0.025, 0.007, (0.61, -0.035, 0.52), IRON("dark"), rot=(0, 60, 0), seg=8)


MODELS = {
	"rocking_chair": rocking_chair, "fur_rug": fur_rug, "hammock": hammock,
	"bunk_bed": bunk_bed, "wardrobe": wardrobe, "bathtub_barrel": bathtub_barrel,
	"washbasin": washbasin, "boot_rack": boot_rack, "writing_desk": writing_desk,
	"world_stone": world_stone, "storage_trunk": storage_trunk, "bar_counter": bar_counter,
	"tap_keg_stand": tap_keg_stand, "mug_rack": mug_rack,
	"bread_oven": bread_oven, "cooking_spit": cooking_spit,
}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
