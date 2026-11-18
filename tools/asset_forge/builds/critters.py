# Tiny harmless cave life (F190, owner Nov 18: "critters: glowing beetles crawling on walls, little moths around
# crystals and lanterns, cave crickets that hop away from you"). Hand-built from the kit (MODEL-RULES Rule 1): chunky,
# faceted, no perfect shapes, every part touching. Real sizes in metres (a little bigger than life, to be seen).
#   blender --background --factory-startup --python builds/critters.py -- [id ...]
# Writes assets/models/critters/<id>.glb and a preview in journey/critters/.
#   glow_beetle   a dark shiny beetle with glowing teal spots on its back, 6 legs, short feelers (crawls on walls)
#   moth_body     a fuzzy pale moth body with feathery feelers (the game adds two wings and flaps them)
#   moth_wing     one wing: pale, with a soft glowing eye spot (the game mirrors it for the other side)
#   cave_cricket  a pale long-legged cave cricket: big hind legs for hopping, very long feelers
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "critters"
JOUR = GAME / "journey" / "critters"


def leg(p0, p1, p2, r, material):
	"""A leg in two bent parts (thigh, shin), thinning to the foot."""
	kit.cone(r, r * 0.8, _len(p0, p1), _mid(p0, p1), material, rot=_rot(p0, p1), verts=5, bevel=0)
	kit.cone(r * 0.8, r * 0.35, _len(p1, p2), _mid(p1, p2), material, rot=_rot(p1, p2), verts=5, bevel=0)


def _len(a, b):
	return math.dist(a, b)


def _mid(a, b):
	return tuple((a[i] + b[i]) / 2 for i in range(3))


def _rot(a, b):
	"""Euler angles (degrees) that turn +Z to point from a to b."""
	d = [b[i] - a[i] for i in range(3)]
	l = math.sqrt(sum(x * x for x in d)) or 1.0
	dx, dy, dz = (x / l for x in d)
	tilt = math.degrees(math.acos(max(-1.0, min(1.0, dz))))
	turn = math.degrees(math.atan2(dy, dx))
	return (0.0, tilt, turn)


def feeler(p0, p1, r, material, bend=0.25, seg=4):
	pts = []
	for k in range(seg + 1):
		u = k / seg
		pts.append(tuple(p0[i] + (p1[i] - p0[i]) * u for i in range(3)))
	pts = [(x, y, z + math.sin(u * math.pi) * bend * _len(p0, p1) * 0.3) for (x, y, z), u in zip(pts, [k / seg for k in range(seg + 1)])]
	for k in range(seg):
		kit.cone(r * (1 - k / seg * 0.6), r * (1 - (k + 1) / seg * 0.6), _len(pts[k], pts[k + 1]) + 0.002, _mid(pts[k], pts[k + 1]), material, rot=_rot(pts[k], pts[k + 1]), verts=4, bevel=0)


def glow_beetle():
	shell = kit.mat("charcoal", rough=0.35)  # dark and a little shiny
	body = kit.mat("stone_dark", rough=0.6)
	spot = kit.glow("glow_cyan", 1.6)  # (4.0 burnt out to white in the game: teal now)
	kit.gem((0, 0.0, 0.022), (0.034, 0.05, 0.02), shell, seed=3)  # the back: two wing cases
	kit.gem((0, 0.052, 0.018), (0.02, 0.018, 0.014), body, seed=4)  # the head
	kit.gem((0, -0.045, 0.016), (0.026, 0.02, 0.014), shell, seed=5)  # the back end
	for (x, y) in ((-0.016, 0.012), (0.016, -0.006), (-0.012, -0.03), (0.013, 0.03)):  # glowing spots on the back
		kit.gem((x, y, 0.038), (0.007, 0.009, 0.004), spot, seed=int(abs(x * 1000 + y * 777)))
	for side in (-1, 1):
		for k, y in enumerate((0.025, 0.0, -0.025)):
			hip = (side * 0.026, y, 0.012)
			knee = (side * 0.05, y + (0.012 if k == 0 else -0.006 * k), 0.022)
			foot = (side * 0.066, y + (0.02 if k == 0 else -0.012 * k), 0.0)
			leg(hip, knee, foot, 0.0045, body)
		feeler((side * 0.008, 0.066, 0.022), (side * 0.03, 0.1, 0.03), 0.0025, body)


def moth_body():
	fur = kit.mat("linen", rough=0.95)
	kit.gem((0, 0, 0.015), (0.012, 0.035, 0.012), fur, seed=11)  # body
	kit.gem((0, 0.036, 0.017), (0.011, 0.01, 0.01), fur, seed=12)  # head
	dark = kit.mat("wood_dark")
	for side in (-1, 1):
		feeler((side * 0.004, 0.044, 0.02), (side * 0.022, 0.07, 0.03), 0.0018, dark, bend=0.4)


def moth_wing():
	"""One wing (the right one): from the body at x = 0 out to x = 0.07, a rounded fore wing and a smaller hind wing,
	a little thickness so it isn't paper, and a soft glowing eye spot."""
	wing = kit.mat("linen", shade=-0.05, rough=0.9)
	r = random.Random(21)
	for (y0, span, depth) in ((0.004, 0.07, 0.034), (-0.022, 0.05, 0.026)):
		verts = []
		n = 9
		for k in range(n + 1):  # the outline: front edge out, then back
			u = k / n
			a = math.pi * u
			x = span * math.sin(a * 0.5 + 0.1) * (0.9 + 0.1 * r.random())
			y = y0 + depth * (0.5 - u) + 0.006 * math.sin(a * 2)
			verts.append((x, y, 0.0))
		top = [(x, y, 0.0015) for (x, y, z) in verts]
		allv = [(0.0, y0, 0.0)] + verts + [(0.0, y0, 0.0015)] + top
		m = len(verts)
		faces = [(0, k + 1, k + 2) for k in range(m - 1)] + [(m + 1, m + 3 + k, m + 2 + k) for k in range(m - 1)]
		kit._mesh_obj("wing", allv, faces, wing, smooth=False)
	kit.gem((0.042, 0.004, 0.002), (0.008, 0.008, 0.0015), kit.glow("glow_cyan", 2.0), seed=22)  # the eye spot


def cave_cricket():
	pale = kit.mat("bone", shade=-0.05, rough=0.7)
	kit.gem((0, 0.0, 0.03), (0.018, 0.04, 0.02), pale, seed=31)  # humped body
	kit.gem((0, 0.045, 0.026), (0.014, 0.014, 0.014), pale, seed=32)  # head
	kit.gem((0, -0.045, 0.024), (0.014, 0.022, 0.014), pale, seed=33)  # back end
	for side in (-1, 1):
		leg((side * 0.012, 0.025, 0.02), (side * 0.03, 0.035, 0.03), (side * 0.04, 0.05, 0.0), 0.003, pale)  # front
		leg((side * 0.014, 0.0, 0.02), (side * 0.035, 0.0, 0.03), (side * 0.045, -0.005, 0.0), 0.003, pale)  # middle
		leg((side * 0.014, -0.03, 0.03), (side * 0.03, -0.02, 0.07), (side * 0.04, -0.09, 0.0), 0.005, pale)  # big hind leg
		feeler((side * 0.005, 0.056, 0.03), (side * 0.05, 0.16, 0.06), 0.0015, pale, bend=0.6, seg=6)


BUILD = {"glow_beetle": glow_beetle, "moth_body": moth_body, "moth_wing": moth_wing, "cave_cricket": cave_cricket}

ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ids = ids or list(BUILD)
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
for item_id in ids:
	kit.reset()
	BUILD[item_id]()
	kit.save(str(OUT / f"{item_id}.glb"), str(JOUR / f"{item_id}.png"), recenter=item_id != "moth_wing")
