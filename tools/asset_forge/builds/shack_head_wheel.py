# Delver's Shack Head Wheel (owner, Nov 25, F899: the big wheel on top of ruin 12's mine headframe, a Shack piece).
# A ~4 m wooden wheel turning on an iron axle along the piece's depth (z). It rests on two beams 4 m apart: the
# axle's two wooden bearing blocks sit on the beams' tops (z = -2 and +2) and the wheel hangs between them.
# Style = the Shack's workbench look (shack_v2.py, imported, never changed): chunky hand-hewn wood, no perfect
# circle: a 16-sided rim of 16 felloes (rim blocks) with a rope groove between two cheek rings (their joints half a
# block round from the felloes', like a real wheel), 8 hewn spokes, a round hub log with 2 iron hoops, an iron
# groove liner, iron plates + wooden pegs on the cheeks, an 8-sided iron axle with end caps and collars.
# Every part sinks ~1 cm into the part it sits on (touching, never two faces in the same place: rule 2).
#   blender --background --factory-startup --python builds/shack_head_wheel.py -- [grey] [out=<folder>] [install=1] [preview]
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import shack_v2 as SH  # noqa: E402

J = K.J
SIZE = (4.0, 4.0, 4.3)   # pieces.gd "head_wheel": size
AX_Y = 2.0               # the axle's height in the piece (the wheel is 4 m across, its bottom at the piece's bottom)
SEAT_Y = 1.75            # the bearing blocks' bottom = the beam top (pieces.gd "head_wheel": seat)
BEAR_Z = 2.0             # the bearing blocks' middle (on the beams' centre lines, 4 m apart)
N = 16                   # rim sides
K.SIZE["head_wheel"] = SIZE


def P(r, a, z):
	return (r * math.cos(a), AX_Y + r * math.sin(a), z)


def bevel(o, w=0.01):
	m = o.modifiers.new("bevel", "BEVEL")
	m.width = w
	m.segments = 2
	m.limit_method = "ANGLE"
	return o


def segment(a0, a1, r0, r1, z0, z1, m, role="board", jit=0.003):
	"""One straight rim block between angles a0 and a1 (inner chord r0, outer chord r1), from z0 to z1."""
	vs = []
	for z in (z0, z1):
		for (r, a) in ((r0, a0), (r1, a0), (r1, a1), (r0, a1)):
			x, y, zz = P(r + J(jit), a, z + J(jit))
			vs.append((x, y, zz))
	faces = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
	o = K.mesh(vs, faces, m or K.T("wood"))
	if role:
		o["role"] = role
	return bevel(o)


def prism_z(cx, cy, r, n, z0, z1, m, a0=0.0, r_in=None, jit=0.0):
	"""An n-sided block (or a ring when r_in is given) round the axle line, from z0 to z1."""
	vs, faces = [], []
	for z in (z0, z1):
		for k in range(n):
			a = a0 + math.tau * k / n
			rr = r + J(jit)
			vs.append((cx + rr * math.cos(a), cy + rr * math.sin(a), z))
	if r_in is None:
		faces.append(tuple(reversed(range(n))))
		faces.append(tuple(range(n, 2 * n)))
		for k in range(n):
			k2 = (k + 1) % n
			faces.append((k, k2, n + k2, n + k))
	else:
		for z in (z0, z1):
			for k in range(n):
				a = a0 + math.tau * k / n
				vs.append((cx + r_in * math.cos(a), cy + r_in * math.sin(a), z))
		o_lo, o_hi, i_lo, i_hi = 0, n, 2 * n, 3 * n
		for k in range(n):
			k2 = (k + 1) % n
			faces.append((o_lo + k, o_lo + k2, o_hi + k2, o_hi + k))      # outside
			faces.append((i_hi + k, i_hi + k2, i_lo + k2, i_lo + k))      # inside
			faces.append((o_lo + k2, o_lo + k, i_lo + k, i_lo + k2))      # one end
			faces.append((o_hi + k, o_hi + k2, i_hi + k2, i_hi + k))      # the other end
	return bevel(K.mesh(vs, faces, m), 0.006)


def iron(v=None):
	return kit.tex_mat("iron", v or K.rng.choice("ab"))


def head_wheel():
	step = math.tau / N
	gap = 0.006 / 1.8           # half a 1.2 cm joint, as an angle at the rim
	# --- the felloes: 16 hewn rim blocks, joints at 11.25 deg + k * 22.5 deg (never where a spoke meets the rim)
	for k in range(N):
		a = k * step
		segment(a - step / 2 + gap, a + step / 2 - gap, 1.60 + J(0.008), 1.83, -0.155, 0.155, None)
	# --- the iron groove liner on the felloes, between the cheeks (its sides go 0.5 cm into the cheeks)
	for k in range(N):
		a = k * step
		segment(a - step / 2 + gap * 1.4, a + step / 2 - gap * 1.4, 1.82, 1.848, -0.145, 0.145, iron("dark"), role=None, jit=0.001)
	# --- the two cheek rings (they make the rope groove): joints at the spoke angles, half a block round
	for s in (-1, 1):
		for k in range(N):
			a = k * step + step / 2
			r_out = 1.972 + J(0.008)
			z0, z1 = (0.14, 0.20 + J(0.004)) if s > 0 else (-0.20 + J(0.004), -0.14)
			segment(a - step / 2 + gap, a + step / 2 - gap, 1.68, r_out, z0, z1, None)
			# two wooden pegs through each cheek block into the felloe
			for f in (-0.28, 0.28):
				x, y, _ = P(1.76, a + step * f, 0)
				SH.peg(x, y, s * 0.20, "z", s)
		# iron plates over the cheek joints (at the spokes), each held by two rivets
		for k in range(N):
			a = k * step
			c = math.cos(a)
			sn = math.sin(a)
			pts = [P(1.72, a - 0.042, 0), P(1.94, a - 0.036, 0), P(1.94, a + 0.036, 0), P(1.72, a + 0.042, 0)]
			z0, z1 = (0.192, 0.212) if s > 0 else (-0.212, -0.192)
			vs = [(p[0], p[1], z) for z in (z0, z1) for p in pts]
			faces = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
			bevel(K.mesh(vs, faces, iron()), 0.004)
			for rr in (1.77, 1.89):
				kit.rivet(K.G((rr * c, AX_Y + rr * sn, s * 0.214)), iron("dark"), r=0.014)
	# --- the 8 spokes: hewn timbers from inside the hub to inside the felloes
	for k in range(8):
		a = k * math.tau / 8 + J(0.01)
		SH.hewn(P(0.26, a, J(0.005)), P(1.64, a, J(0.005)), 0.098)
	# --- the hub: a round log along the axle, two iron hoops, iron collars where the axle comes out
	SH.real_log((0.0, AX_Y, -0.26), (0.0, AX_Y, 0.26), 0.42, "round", stub=False)
	for z in (-0.17, 0.17):
		prism_z(0.0, AX_Y, 0.468, 12, z - 0.035, z + 0.035, iron(), r_in=0.37)
	for s in (-1, 1):
		z0, z1 = sorted((s * 0.24, s * 0.31))
		prism_z(0.0, AX_Y, 0.16, 8, z0, z1, iron("dark"), a0=math.pi / 8)
	# --- the axle: 8-sided iron, right through, its ends in the end caps
	prism_z(0.0, AX_Y, 0.1, 8, -2.128, 2.128, iron("dark"), a0=math.pi / 8)
	# --- the bearing blocks on the beams: a short hewn timber each, an iron strap over the axle with two bolts,
	# and an 8-sided iron end cap on the axle's end
	for s in (-1, 1):
		zc = s * BEAR_Z
		SH.hewn((-0.26, SEAT_Y + 0.128, zc + J(0.004)), (0.26, SEAT_Y + 0.128 + J(0.004), zc), 0.124)
		K.blk((0.0, AX_Y + 0.105, zc), (0.36, 0.05, 0.18), iron("dark"), bevel=0.006)
		for x in (-0.15, 0.15):
			K.blk((x, AX_Y + 0.05, zc), (0.04, 0.16, 0.05), iron("dark"), bevel=0.004)
			kit.rivet(K.G((x, AX_Y + 0.131, zc)), iron("dark"), r=0.016)
		z0, z1 = sorted((s * 2.118, s * 2.143))
		prism_z(0.0, AX_Y, 0.15, 8, z0, z1, iron(), a0=math.pi / 8)


PIECES = {"head_wheel": head_wheel}


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), K.OUT)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in PIECES:
		K.rng.seed(sum(map(ord, name + "v2")))
		kit.reset()
		PIECES[name]()
		K.fit_check(name)
		if grey:
			SH.make_grey()
		else:
			SH.paint3()
		png = str(K.JOUR / f"{name}__plank_root.png") if install else (str(out_dir / f"{name}.png") if "preview" in args else None)
		kit.save(str(out_dir / f"{name}__plank_root.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
