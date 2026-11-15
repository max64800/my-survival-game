# Food and drink (folder: items), hand-built from the kit: bowls, pots, skewers, pies, roasts, tankards, cups, bottles.
#   blender --background --factory-startup --python builds/items_food.py -- [item_id ...]
import math
import random
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "items"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "items"


def col(name, rgb, **kw):
	kit.COLORS[name] = rgb
	return kit.mat(name, **kw)


def chunks(cx, cy, z, r, colours, n=7, size=0.03, seed=3):
	if not colours:
		return
	rr = random.Random(seed)
	for k in range(n):
		a, d = rr.uniform(0, 6.28), rr.uniform(0, r)
		c = colours[k % len(colours)]
		o = kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d, z), (size, size * 0.9, size * 0.7), col(f"ch{c}", c, rough=0.5), seed=k + seed)
		kit.soft(o, 1)


def bowl(stew, bits, kind="wood", r=0.12, garnish=None, glow=0.0):
	m = kit.tex_mat(kind if kind != "wood" else "wood", "b")
	kit.cone(r * 0.7, r, 0.075, (0, 0, 0.0375), m, verts=16, bevel=0.01)
	kit.ring(r, 0.012, (0, 0, 0.075), kit.tex_mat(kind, "dark") if kind != "wood" else kit.tex_mat("wood", "dark"), seg=20)
	kit.cylinder(r - 0.012, 0.01, (0, 0, 0.079), col("stew" + str(stew), stew, glow=glow, rough=0.3), verts=18, bevel=0)
	chunks(0, 0, 0.086, r * 0.6, bits)
	if garnish:
		for k in range(3):
			kit.cone(0.012, 0.0, 0.04, (0.02 * k - 0.02, 0.03, 0.09), col("herb", (0.3, 0.55, 0.2)), rot=(30, 0, k * 60), verts=4, bevel=0)


def pot(stew, bits, kind="clay"):
	kit.tcyl(kind, 0.12, 0.12, (0, 0, 0.06), verts=14)
	kit.ring(0.12, 0.016, (0, 0, 0.12), kit.tex_mat(kind, "dark"), seg=18)
	for s in (-1, 1):
		kit.ring(0.03, 0.009, (s * 0.13, 0, 0.09), kit.tex_mat(kind, "dark"), rot=(90, 0, 90), seg=10)
	kit.cylinder(0.108, 0.01, (0, 0, 0.124), col("stew" + str(stew), stew, rough=0.3), verts=16, bevel=0)
	chunks(0, 0, 0.13, 0.07, bits)


def skewer(colours, glow=0.0):
	kit.cylinder(0.006, 0.42, (0, 0, 0.04), kit.tex_mat("wood", "c"), rot=(0, 90, 10), verts=6, bevel=0)
	for k in range(5):
		x = -0.14 + k * 0.065
		c = colours[k % len(colours)]
		o = kit.gem((x, x * 0.17, 0.045), (0.032, 0.03, 0.03), col(f"sk{c}{glow}", c, glow=glow, rough=0.45), seed=k)
		kit.roughen(o, 0.004, 1, seed=k)
		kit.soft(o, 1)


def pie(top, mushrooms=False):
	kit.cone(0.13, 0.15, 0.05, (0, 0, 0.025), kit.tex_mat("clay", "b"), verts=18, bevel=0.008)
	crust = col("crust", (0.82, 0.58, 0.3), rough=0.6)
	o = kit.gem((0, 0, 0.055), (0.135, 0.135, 0.035), crust, seed=2)
	kit.soft(o, 2)
	kit.ring(0.135, 0.018, (0, 0, 0.05), crust, seg=22)
	lattice = col("crust_d", (0.7, 0.45, 0.22))
	for k in range(3):
		for rz in (0, 90):
			kit.box((0.17, 0.016, 0.01), (0, 0, 0.088), lattice, bevel=0.004, wobble=0.002, rot=(0, 0, rz)).location = (
				(0, -0.045 + k * 0.045, 0.072) if rz == 0 else (-0.045 + k * 0.045, 0, 0.074))
	if mushrooms:
		for (x, y) in ((-0.04, 0.02), (0.05, -0.03)):
			kit.mushroom((x, y, 0.07), 0.3, cap=top, seed=int(x * 100))
	else:
		chunks(0, 0, 0.09, 0.05, [top], n=3, size=0.02)


def board(food):
	kit.tbox("wood", (0.32, 0.2, 0.025), (0, 0, 0.0125), variant="c", bevel=0.006)
	food()


def steak(rgb=(0.5, 0.25, 0.15), grill=False):
	o = kit.gem((0, 0, 0.05), (0.12, 0.08, 0.03), col("steak" + str(rgb), rgb, rough=0.6), seed=3)
	kit.roughen(o, 0.006, 1, seed=3)
	kit.soft(o, 1)
	if grill:
		for k in range(4):
			kit.cylinder(0.006, 0.12, (-0.05 + k * 0.035, 0, 0.078), kit.mat("charcoal"), rot=(90, 0, 30), verts=6, bevel=0)


def roast(shell=False):
	steak((0.45, 0.22, 0.12), grill=False)
	kit.cylinder(0.018, 0.1, (0.13, 0, 0.05), kit.mat("bone"), rot=(0, 90, 0), verts=8, bevel=0.004)
	kit.gem((0.18, 0, 0.05), (0.03, 0.03, 0.03), kit.mat("bone"), seed=2)
	if shell:
		kit.gem((-0.06, 0.05, 0.08), (0.06, 0.04, 0.02), col("chitin", (0.2, 0.28, 0.2), rough=0.4), seed=6)


def snail_on_stick():
	kit.cylinder(0.007, 0.36, (0, 0, 0.05), kit.tex_mat("wood", "c"), rot=(0, 90, 0), verts=6, bevel=0)
	for k in range(4):
		kit.ring(0.06 * (1 - k * 0.22), 0.025 * (1 - k * 0.15), (0.05, 0, 0.05 + k * 0.02), col("snailc", (0.6, 0.42, 0.3), rough=0.5), seg=16)


def mash(rgb):
	bowl(rgb, [], r=0.12)
	o = kit.gem((0, 0, 0.09), (0.09, 0.09, 0.04), col("mash" + str(rgb), rgb, rough=0.7), seed=4)
	kit.roughen(o, 0.008, 1, seed=4)
	kit.soft(o, 1)
	kit.box((0.025, 0.025, 0.012), (0.01, 0.0, 0.135), col("butter", (1.0, 0.9, 0.5)), bevel=0.004, wobble=0)


def risotto():
	bowl((0.85, 0.8, 0.65), [(0.85, 0.82, 0.7)], r=0.12)
	chunks(0, 0, 0.08, 0.08, [(0.9, 0.86, 0.75)], n=20, size=0.012, seed=8)
	chunks(0, 0, 0.09, 0.04, [(0.2, 0.14, 0.2)], n=3, size=0.022, seed=2)


def tankard(liquid, foam=True):
	kit.tcyl("wood", 0.075, 0.17, (0, 0, 0.085), verts=12)
	for z in (0.03, 0.14):
		kit.ring(0.077, 0.01, (0, 0, z), kit.tex_mat("iron"), seg=16)
	kit.ring(0.045, 0.014, (0.09, 0, 0.09), kit.tex_mat("wood", "dark"), rot=(90, 0, 0), seg=12)
	kit.cylinder(0.068, 0.01, (0, 0, 0.165), col("drink" + str(liquid), liquid, rough=0.15), verts=14, bevel=0)
	if foam:
		o = kit.gem((0, 0, 0.175), (0.07, 0.07, 0.02), col("foam", (0.95, 0.92, 0.85), rough=0.8), seed=3)
		kit.soft(o, 1)


def cup(liquid, glow=0.0):
	kit.cone(0.05, 0.065, 0.1, (0, 0, 0.05), kit.tex_mat("clay", "b"), verts=12, bevel=0.008)
	kit.ring(0.065, 0.008, (0, 0, 0.1), kit.tex_mat("clay", "dark"), seg=16)
	kit.ring(0.03, 0.01, (0.07, 0, 0.06), kit.tex_mat("clay", "dark"), rot=(90, 0, 0), seg=10)
	kit.cylinder(0.06, 0.008, (0, 0, 0.096), col("cup" + str(liquid), liquid, glow=glow, rough=0.15), verts=14, bevel=0)


def bottle(liquid, glow=0.2):
	glass = kit.mat("water_light", -0.2, rough=0.08)
	kit.cylinder(0.06, 0.14, (0, 0, 0.07), col("bt" + str(liquid), liquid, glow=glow, rough=0.06, metal=0.1), verts=12, bevel=0.02)
	kit.ring(0.06, 0.006, (0, 0, 0.13), glass, seg=14)
	kit.cone(0.06, 0.02, 0.06, (0, 0, 0.17), glass, verts=12, bevel=0)
	kit.cylinder(0.022, 0.04, (0, 0, 0.21), kit.tex_mat("wood", "c"), verts=8, bevel=0.004)
	kit.rope_wrap((0, 0, 0), 0.025, 0.19, 0.2, 2, thick=0.005)


def jug(liquid):
	o = kit.gem((0, 0, 0.1), (0.1, 0.1, 0.1), kit.tex_mat("clay", "b"), seed=2)
	kit.soft(o, 2)
	kit.tcyl("clay", 0.035, 0.07, (0, 0, 0.21), verts=10, variant="dark")
	kit.ring(0.06, 0.012, (0.08, 0, 0.15), kit.tex_mat("clay", "dark"), rot=(90, 0, 0), seg=12)
	kit.cylinder(0.03, 0.04, (0, 0, 0.25), kit.tex_mat("wood", "c"), verts=8, bevel=0.004)
	kit.rope_wrap((0, 0, 0), 0.038, 0.19, 0.205, 2, thick=0.006)


MEAT, MUSH, TEAL, RED, BROWN = (0.5, 0.22, 0.14), (0.55, 0.4, 0.28), (0.25, 0.75, 0.75), (0.75, 0.25, 0.15), (0.4, 0.26, 0.15)
B = {
	"dish_glowcap_skewer": lambda: skewer([TEAL, (0.9, 0.85, 0.75)], glow=0.25),
	"dish_seared_critter": lambda: board(lambda: roast()),
	"dish_firecap_skewer": lambda: skewer([RED, (0.95, 0.6, 0.2)], glow=0.15),
	"dish_tuber_mash": lambda: mash((0.85, 0.75, 0.5)),
	"dish_hollowcap_stew": lambda: bowl((0.4, 0.25, 0.14), [MUSH, BROWN], garnish=True),
	"dish_glow_broth": lambda: bowl((0.2, 0.55, 0.5), [TEAL], glow=0.3),
	"dish_miners_pie": lambda: pie(MEAT),
	"dish_hearth_stew": lambda: pot((0.42, 0.22, 0.1), [MEAT, (0.8, 0.6, 0.3), (0.3, 0.5, 0.2)], kind="iron"),
	"dish_beetle_roast": lambda: board(lambda: roast(True)),
	"dish_stalk_steak": lambda: board(lambda: steak((0.8, 0.7, 0.55))),
	"dish_ember_skewer": lambda: skewer([(0.95, 0.45, 0.15)], glow=0.4),
	"dish_truffle_risotto": risotto,
	"dish_chitin_crunch": lambda: bowl((0.6, 0.45, 0.25), [(0.25, 0.32, 0.22), (0.7, 0.55, 0.3)]),
	"dish_spore_ward_stew": lambda: bowl((0.4, 0.3, 0.45), [(0.4, 0.6, 0.3), (0.5, 0.35, 0.55)], kind="clay"),
	"dish_bug_hotpot": lambda: pot((0.65, 0.25, 0.1), [(0.86, 0.78, 0.6), RED]),
	"dish_jungle_pie": lambda: pie("mushroom_red", mushrooms=True),
	"dish_cooked_snail": snail_on_stick,
	"dish_roasted_bug": lambda: board(lambda: steak((0.75, 0.55, 0.3))),
	"dish_snail_stew": lambda: bowl((0.5, 0.38, 0.3), [(0.7, 0.52, 0.5), MUSH]),
	"dish_bug_stew": lambda: bowl((0.55, 0.4, 0.2), [(0.86, 0.78, 0.6), MUSH], kind="clay"),
	"drink_bellcap_juice": lambda: cup((0.55, 0.7, 0.95)),
	"drink_glowcap_tea": lambda: cup((0.3, 0.8, 0.75), glow=0.3),
	"drink_firecap_cordial": lambda: bottle((0.85, 0.3, 0.12)),
	"drink_moss_ale": lambda: tankard((0.5, 0.6, 0.25)),
	"drink_spore_mead": lambda: jug((0.5, 0.3, 0.55)),
	"drink_deep_stout": lambda: tankard((0.12, 0.08, 0.06)),
}

ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ids = ids or list(B)
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
for item_id in ids:
	kit.reset()
	try:
		B[item_id]()
		out = OUT / f"{item_id}.glb"
		kit.save(str(out), str(JOUR / f"{item_id}.png"))
		shutil.copy(out, JOUR / f"{item_id}.glb")
	except Exception as e:
		print(f"ITEM_FAILED {item_id}: {e!r}")
