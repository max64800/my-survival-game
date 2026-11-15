# Cave Bat (folder: monsters): a dog-sized cave bat, wings ~1.5 m. Furry body with a lighter ruff,
# big ears, a pug snout with fangs, glowing eyes; real bat wings (arm + finger bones with skin
# stretched between, scalloped back edge). Wings are separate parts so the game can flap them.
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
ck.reset()
ARGS = sys.argv[sys.argv.index("--") + 1:]
V = next((int(a[2:]) for a in ARGS if a.startswith("v=")), 0)  # 0 brown, 1 ash grey, 2 rust, 3 sandy
SUF = "" if V == 0 else f"_v{V}"
rnd = random.Random(5 + V * 31)
TORN = V in (1, 3)  # an old fight left a notch in one ear

fur = ck.skin("bat_fur" + SUF, tile=0.22, rough=0.95)
ruff = ck.color("bat_ruff", (0.27, 0.22, 0.19), rough=0.95)
skin = ck.skin("bat_skin" + SUF, tile=0.3, rough=0.6)
wingskin = ck.skin("bat_wing" + SUF, tile=0.45, rough=0.7)
claw = ck.color("bat_claw", (0.12, 0.1, 0.09), rough=0.4)
fang = ck.color("bat_fang", (0.9, 0.86, 0.76), rough=0.35)
eye = ck.eye_mat([(1.0, 0.7, 0.25), (1.0, 0.82, 0.4), (1.0, 0.55, 0.2), (0.95, 0.75, 0.3)][V % 4])

Z = 0.55  # body height while flying (the game adds the hover)

# ---- body: a fat furry torso, a lighter ruff round the neck
ck.loft("torso", [((0, 0.27, Z - 0.03), 0.07, 0.06), ((0, 0.18, Z - 0.01), 0.16, 0.13), ((0, 0.04, Z), 0.2, 0.18),
	((0, -0.1, Z + 0.01), 0.19, 0.17), ((0, -0.19, Z + 0.03), 0.13, 0.12)], fur, sides=14)
for k in range(22):  # ruff: shaggy, uneven tufts around the neck and chest
	a = rnd.uniform(-0.6, 3.75)
	r = rnd.uniform(0.13, 0.17)
	ck.blob((r * math.cos(a), -0.15 + rnd.uniform(-0.04, 0.03), Z + 0.03 + r * 0.9 * math.sin(a)),
		(rnd.uniform(0.035, 0.055), rnd.uniform(0.05, 0.08), rnd.uniform(0.03, 0.045)), fur, seed=k, jitter=0.45)
# ---- head
H = Vector((0, -0.29, Z + 0.06))
ck.blob(tuple(H), (0.13, 0.12, 0.115), fur, seed=2)
ck.loft("snout", [(H + Vector((0, -0.06, -0.02)), 0.065, 0.055), (H + Vector((0, -0.12, -0.03)), 0.05, 0.045),
	(H + Vector((0, -0.145, -0.03)), 0.035, 0.03)], skin, sides=10)
ck.loft("noseleaf", [(H + Vector((0, -0.14, 0.0)), 0.03, 0.006), (H + Vector((0, -0.14, 0.05)), 0.012, 0.004)], skin, sides=8)
ck.loft("jaw", [(H + Vector((0, -0.05, -0.07)), 0.055, 0.025), (H + Vector((0, -0.12, -0.075)), 0.035, 0.018)], skin, sides=8)
for s in (-1, 1):
	ck.limb(f"fang{s}", [H + Vector((s * 0.025, -0.125, -0.045)), H + Vector((s * 0.022, -0.128, -0.085))], 0.012, 0.002, fang, sides=6, subsurf=0)
	# Big pointed ears (flattened, skin inside)
	es = rnd.uniform(0.88, 1.12)  # ear size differs a little from bat to bat
	if TORN and s < 0:
		# Torn ear: the tip is missing and the edge is ragged.
		ear = [(H + Vector((s * 0.05, 0.0, 0.07)), 0.055, 0.016), (H + Vector((s * 0.09, 0.02, 0.17 * es)), 0.05, 0.012),
			(H + Vector((s * 0.1, 0.03, 0.19 * es)), 0.035, 0.01)]
		ck.loft(f"ear{s}", ear, skin, sides=10, up=Vector((0, -1, 0)))
		for k in range(3):
			kit.crystal(tuple(H + Vector((s * (0.08 + k * 0.015), 0.03, 0.19 * es))), 0.008, 0.02 + 0.01 * k, skin,
				tilt=(0, s * 20, 0), sides=3)
	else:
		ear = [(H + Vector((s * 0.05, 0.0, 0.07)), 0.055, 0.016), (H + Vector((s * 0.09, 0.02, 0.17 * es)), 0.05, 0.012),
			(H + Vector((s * 0.12, 0.04, 0.25 * es)), 0.022, 0.008), (H + Vector((s * 0.13, 0.05, 0.28 * es)), 0.004, 0.003)]
		ck.loft(f"ear{s}", ear, skin, sides=10, up=Vector((0, -1, 0)))
	ck.blob(tuple(H + Vector((s * 0.05, -0.085, 0.035))), (0.024, 0.02, 0.022), eye, seed=7, jitter=0.02)
	# Little hind legs trailing back, with hooked toes (what it hangs from the ceiling by)
	hip = Vector((s * 0.07, 0.18, Z - 0.04))
	foot = Vector((s * 0.1, 0.36, Z - 0.08))
	ck.limb(f"leg{s}", [hip, (hip + foot) / 2 + Vector((0, 0, -0.02)), foot], 0.03, 0.015, skin, sides=7)
	for t in (-1, 0, 1):
		ck.limb(f"toe{s}{t}", [foot, foot + Vector((s * 0.015 + t * 0.015, 0.05, -0.01)), foot + Vector((s * 0.02 + t * 0.02, 0.06, -0.035))],
			0.008, 0.002, claw, sides=5, subsurf=0)
# Tail skin between the legs
ck.membrane("tailskin", [(-0.07, 0.17, Z - 0.04), (-0.1, 0.36, Z - 0.08), (0, 0.42, Z - 0.07), (0.1, 0.36, Z - 0.08), (0.07, 0.17, Z - 0.04)],
	wingskin, thick=0.008)


def wing(s):
	"""One wing, built on the +X side and mirrored for the left (s = -1). Hinge at the shoulder."""
	def P(x, y, z):
		return Vector((s * x, y, z))
	shoulder = P(0.12, -0.08, Z + 0.04)
	with ck.part("wing_r" if s > 0 else "wing_l", hinge=tuple(shoulder)):
		elbow = P(0.3, 0.03, Z + 0.08)
		wrist = P(0.52, -0.12, Z + 0.07)
		tips = [P(0.8, -0.02, Z + 0.0), P(0.77, 0.2, Z - 0.02), P(0.6, 0.36, Z - 0.03), P(0.38, 0.36, Z - 0.03)]
		ck.limb("upperarm", [shoulder, (shoulder + elbow) / 2 + Vector((0, 0, 0.02)), elbow], 0.035, 0.024, skin, sides=8, knobs=(2,))
		ck.limb("forearm", [elbow, (elbow + wrist) / 2 + Vector((0, 0, 0.015)), wrist], 0.024, 0.018, skin, sides=8, knobs=(2,))
		for i, tip in enumerate(tips):
			mid = wrist.lerp(tip, 0.5) + Vector((0, 0, 0.015))
			ck.limb(f"finger{i}", [wrist, mid, tip], 0.014, 0.005, skin, sides=6, knobs=(1,))
		# Thumb claw pointing forward from the wrist
		ck.limb("thumb", [wrist, wrist + P(0.02, -0.05, 0.01), wrist + P(0.035, -0.075, -0.015)], 0.012, 0.003, claw, sides=6, subsurf=0)
		# The skin: shoulder -> along the arm -> each fingertip, sagging in scallops between them -> back to the flank
		flank = P(0.08, 0.17, Z - 0.03)
		outline = [shoulder, P(0.3, -0.02, Z + 0.08), wrist, tips[0]]
		for a, b in zip(tips, tips[1:] + [flank]):
			bow = a.lerp(b, 0.5).lerp(wrist, 0.24) + Vector((0, 0, -0.01))  # scallop: the edge curves inward
			for t in (0.2, 0.4, 0.6, 0.8):
				outline.append((1 - t) ** 2 * a + 2 * (1 - t) * t * bow + t * t * b)
			outline.append(b)
		ck.membrane("skin", outline, wingskin, thick=0.01, center=P(0.42, 0.1, Z + 0.03))


def folded(s):
	"""The same wing folded for sleeping: arm bones lying along the body, the skin wrapped round it
	like a cloak. Hidden in flight; the game shows it (and hides the open wing) while it roosts."""
	def P(x, y, z):
		return Vector((s * x, y, z))
	shoulder = P(0.13, -0.1, Z + 0.06)
	with ck.part("fold_r" if s > 0 else "fold_l", hinge=tuple(shoulder)):
		wrist = P(0.2, 0.3, Z - 0.02)
		ck.limb("foldarm", [shoulder, P(0.22, 0.08, Z + 0.08), wrist], 0.03, 0.02, skin, sides=8, knobs=(1,))
		ck.limb("foldthumb", [wrist, wrist + P(0.0, 0.04, 0.04), wrist + P(-0.01, 0.06, 0.02)], 0.012, 0.003, claw, sides=6, subsurf=0)
		# The cloak: from the arm (top) down around the flank and under the belly, a little baggy.
		# The cloak curves round the body from the arm on top, down the flank, to under the belly.
		ys = [-0.2, -0.1, 0.02, 0.14, 0.26, 0.36]
		radii = [(0.17, 0.15), (0.23, 0.21), (0.25, 0.23), (0.24, 0.22), (0.2, 0.19), (0.13, 0.13)]
		ck.wrap_sheet("cloak", ys, radii, Z + 0.0, math.radians(70), math.radians(-95), wingskin, side=s,
			thick=0.012, steps=9, scallop=0.03)


wing(1)
wing(-1)
folded(1)
folded(-1)
ck.save(out, preview)
