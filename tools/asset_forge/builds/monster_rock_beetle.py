# Rock Beetle (folder: monsters): a charging cave beetle. A domed stone shell with moss, a front
# shield with a curved horn, hooked jaws, clubbed feelers, six spiky jointed legs (separate parts so
# they walk) and a pale soft back end with a glowing gland (its weak spot: double damage).
# Add "great" after the output paths for the Great Rock Beetle (bigger horn, side horns, more moss),
# and "v=0..3" for one of four individuals: horn straight / bent / broken / forked, different knobs
# (rock, pebbles, mossy rock, gem clusters), more or less moss. The game picks one per beetle.
# Owner's design: docs/design/monsters-first-three.md. Built by Claude 3 with creature_kit.
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402
import kit  # noqa: E402
from mathutils import Vector  # noqa: E402

out, preview = kit.args()
ARGS = sys.argv[sys.argv.index("--") + 1:]
GREAT = "great" in ARGS
V = next((int(a[2:]) for a in ARGS if a.startswith("v=")), 0)
ck.reset()
rnd = random.Random((23 if GREAT else 17) * 10 + V)

# Look: based on real "ironclad" beetles (Zopherus): armor covered in close round knobs, four big
# knobs at the back end, a grainy front shield, dark speckles, matte and very hard.
shell = ck.skin("beetle_rock_dark" if GREAT else "beetle_rock", tile=0.38, rough=0.9)
wax = ck.skin("beetle_wax", tile=0.45, rough=0.75)  # the wing cases: matte dark wax with black drops
KNOBS = [ck.skin("beetle_rock", tile=0.2, rough=0.9), ck.skin("pebble_light", tile=0.25, rough=0.55),
	ck.skin("pebble_warm", tile=0.25, rough=0.55), ck.skin("pebble_dark", tile=0.25, rough=0.5)]
mossy = ck.skin("mossy_rock", tile=0.22, rough=0.95)
GEM = [((1.0, 0.62, 0.18), "gem_amber"), ((0.25, 0.85, 0.8), "gem_teal"), ((0.62, 0.35, 0.95), "gem_violet"), ((1.0, 0.62, 0.18), "gem_amber")][V % 4]
gem = ck.color(GEM[1], GEM[0], rough=0.15, glow=0.55)
MOSS = [0.5, 0.1, 1.0, 0.6][V % 4] * (1.4 if GREAT else 1.0)   # how mossy this one is
GEMS = [1, 3, 0, 2][V % 4] + (1 if GREAT else 0)              # how many knobs are gem clusters
shell_dark = ck.skin("beetle_rock_dark", tile=0.38, rough=0.9)
chitin = ck.skin("chitin", tile=0.3, rough=0.35)        # legs, head, jaws: dark and a bit glossy
soft = ck.skin("beetle_soft", tile=0.35, rough=0.6)
horn = ck.color("beetle_horn", (0.72, 0.66, 0.55), rough=0.5)  # pale tips only
horn_base = ck.color("beetle_horn_base", (0.2, 0.17, 0.14), rough=0.4)
moss = ck.color("beetle_moss", (0.24, 0.31, 0.1), rough=0.95)
moss_lite = ck.color("beetle_moss_lite", (0.35, 0.41, 0.15), rough=0.95)
gland = ck.color("beetle_gland", (0.45, 0.95, 0.5), rough=0.3, glow=0.8)
eye = ck.eye_mat((1.0, 0.75, 0.3))
# The cracks between the knobs: dark normally; when it charges the game makes them glow like coals.
vein = ck.color("vein", (0.09, 0.07, 0.06), rough=0.6)
vein.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.32, 0.08, 1)
vein.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.0
SP = 1.45 if GREAT else 1.0  # spikes: bigger and more on the great one

# ---- the two wing cases (elytra), domed, meeting in a groove down the middle
YS = [-0.2, -0.1, 0.05, 0.2, 0.35, 0.47, 0.56]
WS = [0.17, 0.21, 0.235, 0.235, 0.215, 0.16, 0.07]
HS = [0.17, 0.23, 0.26, 0.25, 0.21, 0.15, 0.06]
ZC = [0.41, 0.42, 0.42, 0.42, 0.41, 0.39, 0.37]


def prof(y):
	y = max(YS[0], min(YS[-1], y))
	for i in range(len(YS) - 1):
		if y <= YS[i + 1]:
			t = (y - YS[i]) / (YS[i + 1] - YS[i])
			return [a + (b - a) * t for a, b in ((WS[i], WS[i + 1]), (HS[i], HS[i + 1]), (ZC[i], ZC[i + 1]))]


def surf(sd, y, a, lift=0.0):
	"""A point on a wing case: a = 0 at the outer side, pi/2 on top, pi at the middle groove."""
	w, h, z = prof(y)
	cx = sd * min(0.118, w * 0.6)
	n = Vector((sd * math.cos(a) / w, 0, math.sin(a) / h)).normalized()
	return Vector((cx + sd * math.cos(a) * w, y, z + math.sin(a) * h)) + n * lift, n


for sd in (-1, 1):
	ck.loft(f"elytron{sd}", [((sd * min(0.118, w * 0.6), y, z), w, h) for y, w, h, z in zip(YS, WS, HS, ZC)], wax, sides=22)
	# Rows of round knobs (bigger toward the back), with glowing-when-angry cracks between the rows.
	rows = [0.3, 0.72, 1.12, 1.55, 2.05]
	for ri, a in enumerate(rows):
		for k in range(9):
			y = -0.14 + k * 0.07 + (0.035 if ri % 2 else 0.0)
			if y > 0.5:
				continue
			great_spike = GREAT and ri == 3 and k % 2 == 0
			p, n = surf(sd, y, a, 0.004)
			if great_spike:  # the great one has a row of short spikes along each wing case
				ck.limb(f"crest{sd}{k}", [p, p + n * 0.07 + Vector((0, 0.02, 0))], 0.025, 0.003, shell_dark, sides=6, subsurf=0)
				continue
			r = (0.034 + 0.018 * (y + 0.15) / 0.65) * rnd.uniform(0.75, 1.35)  # chunky knobs, bigger toward the back
			roll = rnd.random()
			if roll < MOSS * 0.25:  # a mossy rock: rock with moss growing over it
				ck.blob(tuple(p), (r * 1.1, r * 1.2, r * 0.8), mossy, seed=ri * 20 + k, jitter=0.25, detail=1, subsurf=0)
				continue
			shape = rnd.choice(((1.0, 1.0, 0.75), (0.75, 1.5, 0.6), (1.25, 1.1, 0.5), (0.9, 0.9, 1.0)))  # round, long, flat, tall
			ck.blob(tuple(p), (r * shape[0], r * shape[1], r * shape[2]), rnd.choice(KNOBS),
				seed=ri * 20 + k + (sd > 0) * 7, jitter=0.2, detail=rnd.choice((1, 1, 2)), subsurf=0)
	for a in (0.5, 0.92, 1.33, 1.8):
		ck.limb(f"crack{sd}{a}", [surf(sd, y, a, -0.002)[0] for y in (-0.17, -0.02, 0.14, 0.3, 0.44)], 0.009, 0.007, vein, sides=5, subsurf=0)
	# The four big knobs at the back end (two on each wing case), like a real ironclad beetle.
	for a in (0.95, 1.9):
		p, n = surf(sd, 0.43, a, 0.01)
		ck.blob(tuple(p), (0.06, 0.065, 0.05), shell_dark, seed=int(a * 10) + sd, jitter=0.12)
	# A flared, spiky rim along the outer edge.
	rim = [surf(sd, y, -0.2, 0.015)[0] for y in (-0.18, -0.05, 0.1, 0.25, 0.38, 0.48)]
	ck.limb(f"rim{sd}", rim, 0.03, 0.022, shell_dark, sides=7)
	count = int(6 * SP) + rnd.randint(-1, 1)
	for k in range(count):
		y = -0.15 + k * (0.6 / count)
		p, n = surf(sd, y, -0.2, 0.02)
		ck.limb(f"spike{sd}{k}", [p, p + Vector((sd * 0.07 * SP, 0.015, -0.035))], 0.02 * SP, 0.002, shell_dark, sides=6, subsurf=0)
ck.limb("groove", [Vector((0, y, z + h * 0.82)) for y, h, z in zip(YS[:-1], HS[:-1], ZC[:-1])], 0.012, 0.01, vein, sides=5)
# Under-belly
ck.loft("belly", [((0, -0.3, 0.27), 0.18, 0.08), ((0, 0.1, 0.25), 0.26, 0.1), ((0, 0.45, 0.27), 0.16, 0.07)], chitin, sides=12)

# ---- front shield (pronotum): grainy, two humps, a furrow, spiky corners; and the horn
ck.loft("shield", [((0, -0.17, 0.4), 0.34, 0.19), ((0, -0.3, 0.41), 0.34, 0.17), ((0, -0.43, 0.39), 0.27, 0.13),
	((0, -0.5, 0.37), 0.17, 0.08)], shell_dark, sides=20)
ck.loft("shield_lip", [((0, -0.44, 0.47), 0.2, 0.03), ((0, -0.5, 0.43), 0.14, 0.025)], shell_dark, sides=10)
ck.limb("furrow", [Vector((0, -0.19, 0.592)), Vector((0, -0.3, 0.584)), Vector((0, -0.4, 0.53))], 0.01, 0.008, vein, sides=5, subsurf=0)
for sd in (-1, 1):
	ck.blob((sd * 0.12, -0.3, 0.55), (0.09, 0.1, 0.06), shell_dark, seed=60 + sd)                  # humps
	for k in range(7):  # grainy knobs on the shield
		gx, gy = sd * rnd.uniform(0.05, 0.25), rnd.uniform(-0.4, -0.2)
		gz = 0.405 + 0.17 * math.sqrt(max(0.0, 1 - (gx / 0.34) ** 2))  # on the shield's surface
		ck.blob((gx, gy, gz), (0.022, 0.022, 0.016), shell, seed=70 + k, detail=1, subsurf=0)
	c = Vector((sd * 0.33, -0.19, 0.4))
	ck.limb(f"corner{sd}", [c, c + Vector((sd * 0.07 * SP, 0.05, -0.02))], 0.03 * SP, 0.003, shell_dark, sides=6, subsurf=0)
	f = Vector((sd * 0.12, -0.47, 0.46))
	ck.limb(f"brow{sd}", [f, f + Vector((sd * 0.02, -0.06 * SP, 0.04 * SP))], 0.02 * SP, 0.002, shell_dark, sides=6, subsurf=0)
hs = (1.35 if GREAT else 1.0) * rnd.uniform(0.9, 1.1)
STYLE = ["curved", "bent", "broken", "forked"][V % 4]
bend = rnd.choice((-1, 1)) * 0.16 * hs if STYLE == "bent" else 0.0  # bent: the tip swings off to one side
horn_path = ck.bezier((0, -0.43, 0.49), (bend * 0.3, -0.62 * hs, 0.52), (bend, -0.66 * hs, 0.74 * hs), n=8, p3=(bend * 1.4, -0.6 * hs, 0.86 * hs))
if STYLE == "broken":
	# Snapped off in a fight: a short stump with a jagged, pale break.
	ck.limb("horn", horn_path[:5], 0.08 * hs, 0.042 * hs, horn_base, sides=10, knobs=())
	end = horn_path[4]
	for k in range(5):
		a = k * 2 * math.pi / 5
		kit.crystal(tuple(end + Vector((math.cos(a) * 0.025 * hs, -0.01, math.sin(a) * 0.025 * hs))), 0.014 * hs, rnd.uniform(0.02, 0.05) * hs,
			horn, tilt=(rnd.uniform(-25, 25), rnd.uniform(-25, 25), 0), sides=4)
else:
	ck.limb("horn", horn_path[:6], 0.08 * hs, 0.03 * hs, horn_base, sides=10, knobs=())  # dark horn
	if STYLE == "forked":  # the tip splits in two
		for sd in (-1, 1):
			ck.limb(f"fork{sd}", [horn_path[5], horn_path[5] + Vector((sd * 0.06 * hs, 0.02, 0.1 * hs))], 0.026 * hs, 0.006, horn, sides=8)
	else:
		ck.limb("horntip", horn_path[5:], 0.03 * hs, 0.008, horn, sides=8)  # pale worn tip
for k in (1, 2, 3) if STYLE != "broken" else (1, 2):  # growth rings on the horn
	a, b = horn_path[k], horn_path[k + 1]
	ck.limb(f"hornring{k}", [a.lerp(b, 0.45), a.lerp(b, 0.55)], (0.08 - k * 0.012) * hs * 1.04, (0.08 - k * 0.012) * hs * 1.03, horn_base, sides=10, subsurf=0)
if GREAT:
	for sd in (-1, 1):  # two shorter side horns on the shield
		ck.limb(f"sidehorn{sd}", ck.bezier((sd * 0.2, -0.36, 0.5), (sd * 0.3, -0.5, 0.58), (sd * 0.3, -0.58, 0.72), n=6), 0.05, 0.01, horn_base, sides=8)

# ---- head, jaws, feelers, eyes (tucked under the front of the shield)
ck.blob((0, -0.56, 0.3), (0.15, 0.12, 0.1), chitin, seed=3)
for s in (-1, 1):
	jaw = ck.bezier((s * 0.08, -0.62, 0.27), (s * 0.13, -0.76, 0.26), (s * 0.03, -0.84, 0.25), n=7)
	ck.limb(f"jaw{s}", jaw, 0.035, 0.008, chitin, sides=8)
	ck.limb(f"jawtip{s}", [jaw[-2], jaw[-1]], 0.012, 0.004, horn, sides=6, subsurf=0)
	ck.blob((s * 0.11, -0.6, 0.34), (0.035, 0.035, 0.032), eye, seed=4, jitter=0.02)
	feeler = ck.bezier((s * 0.09, -0.62, 0.36), (s * 0.2, -0.72, 0.42), (s * 0.27, -0.8, 0.4), n=7)
	ck.limb(f"feeler{s}", feeler, 0.012, 0.008, chitin, sides=6)
	for k in range(3):  # clubbed, leafy feeler tips
		ck.blob(tuple(feeler[-1] + Vector((s * 0.012 * k, -0.015 * k, 0.012 * (k - 1)))), (0.022, 0.012, 0.018), chitin, seed=k + 8)

# ---- the soft back end with the glowing gland (its weak spot)
ck.loft("abdomen", [((0, 0.36, 0.3), 0.26, 0.14), ((0, 0.52, 0.3), 0.22, 0.13), ((0, 0.64, 0.29), 0.15, 0.1),
	((0, 0.72, 0.28), 0.09, 0.07)], soft, sides=14)
for i in range(3):  # soft ring folds
	y = 0.5 + i * 0.08
	ck.loft(f"fold{i}", [((0, y - 0.01, 0.3), 0.21 - i * 0.05, 0.125 - i * 0.025), ((0, y + 0.01, 0.3), 0.21 - i * 0.05, 0.125 - i * 0.025)], soft, sides=14, subsurf=0)
ck.blob((0, 0.75, 0.28), (0.065, 0.06, 0.06), gland, seed=40, jitter=0.05)

# ---- moss and pebbles on the shell
for g in range(GEMS):  # gem clusters growing out of the shell (they glow softly)
	sd = rnd.choice((-1, 1))
	p, n = surf(sd, rnd.uniform(-0.05, 0.4), rnd.uniform(0.6, 1.9), 0.0)
	for c in range(rnd.randint(3, 5)):
		tilt = (rnd.uniform(-35, 35), rnd.uniform(-35, 35), rnd.uniform(0, 360))
		kit.crystal(tuple(p + Vector((rnd.uniform(-0.04, 0.04), rnd.uniform(-0.04, 0.04), 0))), rnd.uniform(0.018, 0.032),
			rnd.uniform(0.08, 0.16) * (1.3 if GREAT else 1.0), gem, tilt=tilt)
for k in range(int((36 if GREAT else 20) * MOSS)):  # moss in the middle groove and around the back knobs
	y = rnd.uniform(-0.1, 0.48)
	sd = rnd.choice((-1, 1))
	a = rnd.uniform(2.3, 3.0) if k % 3 else rnd.uniform(1.0, 1.9)
	p, n = surf(sd, y, a, 0.0)
	ck.blob(tuple(p), (rnd.uniform(0.02, 0.04), rnd.uniform(0.025, 0.05), 0.012), moss if k % 4 else moss_lite, seed=k + 50, jitter=0.4, detail=1, subsurf=0)


# ---- six legs, each its own part turning at the hip (front legs reach forward, back legs back)
def leg(s, i, y, reach):
	hip = Vector((s * 0.17, y, 0.29))
	with ck.part(f"leg_{'l' if s < 0 else 'r'}{i}", hinge=tuple(hip)):
		knee = Vector((s * 0.38, y + reach * 0.5, 0.36))
		foot = Vector((s * 0.5, y + reach, 0.03))
		ck.limb("thigh", [hip, hip.lerp(knee, 0.5) + Vector((0, 0, 0.035)), knee], 0.065, 0.045, chitin, sides=8, knobs=(2,))
		ck.limb("shin", [knee, knee.lerp(foot, 0.5) + Vector((s * 0.025, 0, 0)), foot], 0.042, 0.022, chitin, sides=8)
		for k in range(3):  # spikes along the shin
			at = knee.lerp(foot, 0.25 + k * 0.22)
			ck.limb(f"spike{k}", [at, at + Vector((s * 0.035, reach * 0.05, 0.02))], 0.01, 0.002, horn, sides=5, subsurf=0)
		ck.limb("toe", [foot, foot + Vector((s * 0.05, reach * 0.12 - 0.02, -0.01)), foot + Vector((s * 0.08, reach * 0.15 - 0.04, 0.0))], 0.014, 0.004, chitin, sides=6)


for s in (-1, 1):
	leg(s, 0, -0.3, -0.18)
	leg(s, 1, 0.0, 0.02)
	leg(s, 2, 0.28, 0.2)

ck.save(out, preview)
