# Ability props (owner, Nov 27, F917): the Healing Brew flask you throw and the Clan Banner you plant.
# Hand-built in the workbench style (chunky, hand-painted kit textures, every part touching).
#   blender --background --factory-startup --python tools/asset_forge/builds/ability_props.py -- [brew_flask clan_banner]
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import GAME, kit, log, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import prism  # noqa: E402
from decor_nov21_ru import BK, CU, IRD, LE, ROPE  # noqa: E402

BREW = lambda: C((0.5, 0.06, 0.05), 0.25, glow=0.25)  # noqa: E731  warm red brew, a soft glow so it reads in the dark
GLASS = lambda: C((0.55, 0.42, 0.36), 0.12, metal=0.1)  # noqa: E731  the thick glass neck and lip
GOLD = lambda: C((0.62, 0.52, 0.3), 0.9)  # noqa: E731  the banner's painted emblem (like the camp flag)


def brew_flask():
	"""A fat round-bellied flask, ~22 cm: red brew showing through, glass neck, cork, a rope tied round the neck."""
	sphere((0, 0, 0.075), 0.075, BREW(), scale=(1.0, 1.0, 0.92), seg=12, rings=8)  # chunky: few sides, no perfect ball
	kit.ring(0.068, 0.012, (0, 0, 0.075), kit.tex_mat("copper", "b"), seg=12)  # a hammered copper band round the belly
	kit.cone(0.045, 0.026, 0.05, (0, 0, 0.158), GLASS(), verts=10, bevel=0.004)  # shoulder into the neck
	kit.cylinder(0.026, 0.04, (0, 0, 0.198), GLASS(), verts=10, bevel=0.004)
	kit.ring(0.028, 0.008, (0, 0, 0.217), GLASS(), seg=12)  # the lip
	kit.tcyl("wood", 0.02, 0.04, (0, 0, 0.235), verts=8, variant="c", bevel=0.005)  # cork
	kit.rope_wrap((0, 0, 0), 0.03, 0.182, 0.2, 2, thick=0.006)
	log((0.028, 0.0, 0.19), (0.07, 0.01, 0.135), 0.006, ROPE(), seg=5, rings=1, ends=False, bend=0)  # the loose rope end


def clan_banner():
	"""A clan banner on a bark pole, ~2.4 m: a T crossbar, a swallow-tailed cloth hanging in front of the pole with the
	anvil-and-hammer on both faces, a copper knob on top, a few stones heaped round its foot."""
	R0 = 0.05
	log((0, 0, 0.0), (0, 0, 2.3), R0, BK(), seg=9, rings=5, bend=0.008, end_m=LE(), r1=0.04)
	kit.cone(0.04, 0.0, 0.16, (0, 0, 2.37), IRD(), verts=6, bevel=0)  # iron spike on top
	kit.ring(0.044, 0.011, (0, 0, 2.29), IRD(), seg=12)
	sphere((0, 0, 2.31), 0.045, CU(), seg=10, rings=7)
	yz, fy = 2.12, -(R0 + 0.045)  # crossbar height; the cloth hangs this far in front of the pole (never through it)
	log((-0.46, fy, yz), (0.46, fy, yz), 0.024, BK(), seg=7, rings=2, bend=0, end_m=LE())
	kit.ring(0.052, 0.012, (0, 0, yz), ROPE(), seg=12)  # the crossbar is lashed to the pole...
	log((0, -0.02, yz), (0, fy, yz), 0.014, ROPE(), seg=5, rings=1, ends=False, bend=0)  # ...by a rope across the gap
	top = yz - 0.03
	r = random.Random(11)
	pts = [(-0.4, top), (0.4, top), (0.4, top - 1.05), (0.0, top - 0.8), (-0.4, top - 1.05)]  # swallow tail
	pts = [(x + r.uniform(-0.01, 0.01), z + (r.uniform(-0.015, 0.015) if z < top else 0)) for (x, z) in pts]
	cloth = prism(pts, fy - 0.006, fy + 0.006, kit.tex_mat("bannercloth", "a"))
	# A darker hem stripe near the top and the emblem, on both faces.
	for side in (-1, 1):
		y0 = fy + side * 0.003  # starts inside the cloth (joined), its face 4-5 mm proud: no shimmer
		hem = prism([(-0.4, top - 0.1), (0.4, top - 0.1), (0.4, top - 0.15), (-0.4, top - 0.15)], y0, y0 + side * 0.007, kit.tex_mat("bannercloth", "dark"))
		cz = top - 0.48
		anv = prism([(-0.14, cz + 0.02), (0.14, cz + 0.02), (0.1, cz - 0.04), (0.05, cz - 0.05), (0.05, cz - 0.12), (0.1, cz - 0.15),
			(-0.1, cz - 0.15), (-0.05, cz - 0.12), (-0.05, cz - 0.05), (-0.16, cz - 0.02)], y0, y0 + side * 0.0075, GOLD())
		ham = prism([(-0.07, cz + 0.2), (0.07, cz + 0.2), (0.07, cz + 0.12), (0.015, cz + 0.12), (0.015, cz + 0.04), (-0.015, cz + 0.04),
			(-0.015, cz + 0.12), (-0.07, cz + 0.12)], y0, y0 + side * 0.0075, GOLD())
	for x in (-0.34, 0.0, 0.34):  # rope loops hold the cloth on the crossbar
		kit.ring(0.03, 0.007, (x, fy, yz - 0.01), ROPE(), rot=(0, 90, 0), seg=10)
	for k in range(5):  # stones heaped round the foot, touching the pole
		a = k * 1.3 + 0.4
		s = 0.07 + 0.02 * (k % 2)
		kit.stone((s * 1.3, s, s * 0.8), (math.cos(a) * (R0 + s * 0.55), math.sin(a) * (R0 + s * 0.55), s * 0.35), rot_z=a)


MODELS = {"brew_flask": brew_flask, "clan_banner": clan_banner}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "abilities"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "abilities"
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
