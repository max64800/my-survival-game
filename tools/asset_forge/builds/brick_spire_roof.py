# Hearthbrick spire roof (owner, Nov 25, F895: the pointed brick roof on Brickcrown Keep's 6-sided left tower).
# One piece = one sixth of a pointed 6-sided roof, sitting on one 2 m triangle (a floor_triangle's outline), so
# six of them on a hexagon of triangles make the whole spire, and it snaps like every other triangle piece.
# Built exactly like the Hearthbrick roof_45 (hearthbrick_v2_roofs.py, imported, never changed): rule 4, a thin
# panel open underneath: dark rafters, underlay boards, curved terracotta pans and caps lapping row over row, a
# pale limestone eave course along the low (outer) edge. The two slanted edges are the spire's hips: each piece
# carries HALF a round hip tile in pale mortar along both, so two neighbours make one round hip with a fine joint
# (each half stays 0.5 cm inside its own edge: rule 2). The top: a sixth of a pale limestone finial.
#   blender --background --factory-startup --python builds/brick_spire_roof.py -- [grey] [out=<folder>] [install=1]
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402
import hearthbrick_v2_roofs as R  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

E = K.E_IN
TRI_IN, TRI_OUT = K.TRI_IN, K.TRI_OUT
SIZE_Y = 3.0          # the piece's height (pieces.gd "roof_spire": size.y, rise)
R_PANEL = 2.6         # the tiled panel's rise (the finial tops it up to SIZE_Y)
FIN_R = 0.2           # the finial's foot radius round the point
K.SIZE["roof_spire"] = ("tri", SIZE_Y)


def facet():
	sl = K.Slope("z", TRI_IN, -TRI_OUT, R_PANEL, R.TOP_V, vlo=-1.0, vhi=1.0)
	cs = math.cos(sl.ang)
	k = sl.k
	# the two slanted edges as (u = z, v = x) half-planes, 0.5 cm inside (rule 2)
	tri = K.tri_planes(1.0, E)
	slanted = [(b, a, c) for (a, b, c) in tri if abs(a) > 0.1]
	R.slope_panel(sl, slanted, eave=True, rafters=())

	def yu(x, z):   # the panel's underside height at (x, z)
		return sl.y0 + k * (TRI_IN - z)
	n_top = R.N_TOP / cs

	# rafters: one up the middle, two beside it, and one under each hip; all stop 45 cm short of the point
	d_max = sl.run - 0.45
	nrm = R.normal(sl)
	stop = [(-1.0, 0.0, -(-TRI_OUT + 0.45))]   # z >= point + 0.45
	inner = [(b, a, c) for (a, b, c) in K.tri_planes(1.0, E + R.RAFT_W * 1.5 + 0.025) if abs(a) > 0.1]
	d_start = R.FD + 0.004
	for v in (-0.5, 0.0, 0.5):
		pl = sl.planes(inner + stop)
		rr = [R.col_range(sl, v + s * R.RAFT_W / 2, pl) for s in (-1, 1)]
		if not all(rr):
			continue
		d0, d1 = max(max(x[0] for x in rr) + 0.005, d_start), min(min(x[1] for x in rr) - 0.006, d_max)
		if d1 - d0 < 0.3:
			continue
		R.box_between(sl.P(sl.u(d0), v, 0.0), sl.P(sl.u(d1), v, 0.0), (1, 0, 0), nrm, R.RAFT_W, R.RAFT_H, kit.tex_mat("wood", "dark"), "timber")

	apex = Vector((0.0, -TRI_OUT))
	for sx in (-1, 1):
		corner = Vector((sx * 1.0, TRI_IN))
		along = (apex - corner)                       # 2 m, corner -> point
		n_in = Vector((-sx * 0.8660254, 0.5))        # level, into the triangle

		def q(f, s, corner=corner, along=along, n_in=n_in):
			p = corner + along * f + n_in * (E + s)
			return Vector((p.x, p.y))   # (x, z)

		def f_in(s, m=0.003):   # where the line s in from the hip clears the eave's front edge by m (the corner is cut to it)
			return (0.5 * (E + s) + E + m) / 1.7320508

		# the hip rafter, just inside the edge
		s_r = 0.004 + R.RAFT_W / 2
		f0 = 0.0
		while TRI_IN - q(f0, s_r + R.RAFT_W / 2).y < d_start + 0.005 or TRI_IN - q(f0, s_r - R.RAFT_W / 2).y < d_start + 0.005:
			f0 += 0.005
		f1 = f0
		while TRI_IN - q(f1 + 0.005, s_r).y < d_max:
			f1 += 0.005
		pa, pb = q(f0, s_r), q(f1, s_r)
		A = Vector((pa.x, yu(pa.x, pa.y), pa.y))
		B = Vector((pb.x, yu(pb.x, pb.y), pb.y))
		dirv = (B - A).normalized()
		side = nrm.cross(dirv).normalized()
		R.box_between(tuple(A), tuple(B), tuple(side), nrm, R.RAFT_W, R.RAFT_H, kit.tex_mat("wood", "dark"), "timber")

		# half a round hip tile (crest at the edge, curving down onto the tiles inward), on a pale mortar bed
		def hw(f):   # narrower near the point, so the two halves of one piece never meet
			r = 2.0 * (1 - f)
			return max(0.05, min(0.13, 0.866 * r / 2 - 0.012))
		f_hi = 1.0 - (FIN_R - 0.03) / 2.0
		tile_top = lambda f, s: yu(*q(f, s)) + n_top   # the pans/caps' top surface near the hip

		def base(f):
			return tile_top(f, hw(f)) + 0.016   # (caps sit up to 4 mm higher than the plan: no shimmer)

		def sag(f):
			return 0.04 + k * 0.5 * hw(f)
		n = 7
		L = f_hi / n
		th = 0.014
		for i in range(n):
			fa, fb = L * i, min(f_hi, L * (i + 1) + 0.03)
			rows = []
			for st in range(5):
				xn = st / 4
				ga = max(fa, f_in(xn * hw(fa) + 0.01))
				ra = base(ga) + sag(ga) * (1 - xn * xn) + K.rng.uniform(0, 0.002)
				rb = base(fb) + sag(fb) * (1 - xn * xn)
				rows.append((xn * hw(ga), ga, ra + 0.022, xn * hw(fb), fb, rb))

			def pt(f, s, y):
				p = q(f, s)
				return (p.x, y, p.y)
			R.tag([R.tile_mesh(pt, rows, th, HB.m_brick())], "ridge", dark=K.rng.random() < 0.1)

		def bed(t):
			f = 0.01 + (f_hi + 0.02 - 0.01) * t
			a = max(0.03, hw(f) - 0.02)
			pts = []
			for s in (0.01, a / 2, a):   # (1 cm in from the hip tile's seam: the underlay's cut edge is at the seam)
				p = q(max(f, f_in(s, 0.012)), s)   # (the tiles' front ends are 9 mm in: no shimmer)
				pts.append((p.x, yu(p.x, p.y) + R.UL1 / cs - 0.004, p.y))
			for s in (a, a / 2, 0.01):
				p = q(max(f, f_in(s, 0.012)), s)   # (the tiles' front ends are 9 mm in: no shimmer)
				top = base(f) + sag(f) * (1 - (s / hw(f)) ** 2) - 0.004
				pts.append((p.x, max(yu(p.x, p.y) + R.UL1 / cs + 0.01, top), p.y))
			return pts
		R.prism(bed, 14, HB.m_mortar(), "mortar")

	# a sixth of the limestone finial: a round foot, a waist, a ball and a point (each sixth 0.5 cm inside its edges)
	tip = Vector((0.0, -TRI_OUT + 4 * E))        # 1 cm from both slanted edges (the cut boards and tiles end at 0.5)
	y_foot = yu(0.0, -TRI_OUT + FIN_R) + R.UL1 / cs
	y_hip = base(f_hi) + sag(f_hi)
	h_top = SIZE_Y - 0.01
	prof = [(FIN_R, y_foot), (FIN_R, y_hip + 0.04), (0.15, y_hip + 0.10), (0.075, h_top - 0.3), (0.11, h_top - 0.2),
		(0.075, h_top - 0.09), (0.0, h_top)]
	nseg = 4
	verts, faces = [], []
	for (r, y) in prof:
		verts.append((tip.x, y, tip.y))
		for j in range(nseg + 1):
			a = math.radians(-30 + 60 * j / nseg)
			verts.append((tip.x + r * math.sin(a), y, tip.y + r * math.cos(a)))
	w = nseg + 2
	for i in range(len(prof) - 1):
		a0, b0 = i * w, (i + 1) * w
		faces.append((a0, b0, b0 + 1, a0 + 1))                         # cut side at -30 deg
		faces.append((a0 + nseg + 1, b0 + nseg + 1, b0, a0))          # cut side at +30 deg
		for j in range(1, nseg + 1):
			faces.append((a0 + j, b0 + j, b0 + j + 1, a0 + j + 1))
	faces.append(tuple(range(nseg + 1, -1, -1)))                     # the foot
	o = K.mesh(verts, faces, HB.m_lime())
	for p in o.data.polygons:
		p.use_smooth = False
	R.tag([o], "lime")


PIECES = {"roof_spire": facet}


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), HB.OUT_DEFAULT)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in PIECES:
		K.rng.seed(sum(map(ord, name + "hearthbrick2")))
		kit.reset()
		PIECES[name]()
		HB.split_big_faces()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			HB.paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
