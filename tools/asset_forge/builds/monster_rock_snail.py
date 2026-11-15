# Rock Snail (folder: monsters): a big, slow cave snail. A heavy coiled stone shell with growth
# ridges, moss and stuck pebbles; one soft, damp body that pulls into the shell when it hides.
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
V = next((int(a[2:]) for a in ARGS if a.startswith("v=")), 0)  # 0 slate, 1 olive, 2 rusty
SUF = "" if V == 0 else f"_v{V}"
rnd = random.Random(11 + V * 13)
MOSS = [1.0, 0.45, 1.5][V % 3]    # how mossy its shell is
STONES = [7, 14, 5][V % 3]        # stones stuck to the shell
CRYSTAL = V % 3 == 2              # one has a crystal growing out of its shell

skin = ck.skin("snail_skin2" + SUF, tile=0.6, rough=0.42)    # bumpy, damp snail skin (tubercles and grooves)
sole = ck.skin("snail_sole", tile=0.45, rough=0.45)
mantle = ck.color("snail_mantle", (0.58, 0.49, 0.39), rough=0.4)   # the fleshy collar at the shell's mouth
stripe = ck.color("snail_stripe", (0.2, 0.17, 0.15), rough=0.4)
frill = ck.color("snail_frill", (0.44, 0.3, 0.16), rough=0.45)    # ochre edge of the creeping skirt
tip = ck.color("snail_tip", (0.16, 0.13, 0.12), rough=0.3)
shell_mat = ck.skin("shell_rock" + SUF, tile=0.55, rough=0.9)
shell_dark = ck.skin("shell_rock_dark" + SUF, tile=0.55, rough=0.9)
moss = ck.color("snail_moss", (0.24, 0.31, 0.10), rough=0.95)
moss_lite = ck.color("snail_moss_lite", (0.36, 0.42, 0.16), rough=0.95)
eye = ck.eye_mat()

# ---- the soft body: one piece from the tail tip to the head. When it hides, the game shrinks it
# to almost nothing toward a hinge INSIDE the shell (tail and all), then only the "peek" eyes show.
with ck.part("soft_body", hinge=(0.03, 0.04, 0.66)):
	spine = ck.bezier((0, 0.7, 0.035), (0, 0.0, 0.17), (0, -0.5, 0.17), n=14, p3=(0, -0.62, 0.44))
	widths = [0.03, 0.08, 0.15, 0.22, 0.28, 0.32, 0.34, 0.34, 0.32, 0.29, 0.25, 0.21, 0.18, 0.16]
	heights = [0.02, 0.05, 0.08, 0.11, 0.14, 0.155, 0.165, 0.17, 0.165, 0.16, 0.155, 0.15, 0.14, 0.13]
	ck.loft("foot", [(p, w, h) for p, w, h in zip(spine, widths, heights)], skin, sides=18)
	# The creeping skirt: wider than the body, with a wavy ochre edge, and the pale sole under it.
	skirt = ck.bezier((0, 0.66, 0.02), (0, 0.0, 0.03), (0, -0.55, 0.05), n=16)
	ck.loft("skirt", [(p, (0.03 + 0.37 * math.sin(min(1.0, (i + 0.5) / 15) * math.pi) ** 0.7) * (1 + 0.04 * math.sin(i * 2.3)), 0.022)
		for i, p in enumerate(skirt)], frill, sides=14)
	ck.loft("sole", [(p, (0.02 + 0.35 * math.sin(min(1.0, (i + 0.5) / 15) * math.pi) ** 0.7), 0.03) for i, p in enumerate(skirt)], sole, sides=12)
	# A raised ridge (keel) down the tail, with a dark stripe on it; two dark stripes along the neck.
	keel = [spine[i] + Vector((0, 0, heights[i] * 0.92)) for i in range(1, 6)]
	ck.limb("keel", keel, 0.012, 0.03, skin, sides=6)
	ck.limb("keel_stripe", [k + Vector((0, 0, 0.012)) for k in keel], 0.008, 0.018, stripe, sides=6)
	for s in (-1, 1):
		neck = [spine[i] + Vector((s * widths[i] * 0.55, 0, heights[i] * 0.8)) for i in range(9, 14)]
		ck.limb(f"neck_stripe{s}", neck, 0.014, 0.012, stripe, sides=6)
	# The mantle: a thick, fleshy collar where the body goes into the shell, with the breathing hole.
	ck.loft("mantle", [((0.02, -0.1, 0.3), 0.27, 0.1), ((0.02, -0.17, 0.31), 0.29, 0.12), ((0.02, -0.24, 0.3), 0.25, 0.1)], skin, sides=18)
	ck.loft("mantle_lip", [((0.02, -0.235, 0.305), 0.255, 0.105), ((0.02, -0.25, 0.3), 0.24, 0.09)], mantle, sides=18, subsurf=0)
	ck.blob((0.27, -0.17, 0.33), (0.032, 0.028, 0.028), tip, seed=9, jitter=0.05)  # breathing hole (snails have one!)
	# Head: two soft snout lobes, a mouth slit, ringed eye stalks with dark tips, short feelers.
	ck.blob((0, -0.66, 0.5), (0.16, 0.16, 0.14), skin, seed=3)
	for s in (-1, 1):
		ck.blob((s * 0.07, -0.76, 0.43), (0.08, 0.07, 0.06), skin, seed=4 + s)    # snout lobes
	ck.loft("mouth", [((-0.07, -0.81, 0.4), 0.012, 0.01), ((0, -0.835, 0.395), 0.014, 0.012), ((0.07, -0.81, 0.4), 0.012, 0.01)], tip, sides=6)
	for s in (-1, 1):
		feel = ck.bezier((s * 0.1, -0.78, 0.46), (s * 0.15, -0.84, 0.44), (s * 0.17, -0.86, 0.4), n=4)
		ck.limb(f"feeler{s}", feel, 0.026, 0.016, skin, sides=7)
		ck.blob(tuple(feel[-1]), (0.018, 0.018, 0.018), tip, seed=7, jitter=0.02)

# ---- eye stalks: separate parts hinged on the head, so the game can sway them (looking around).
for s in (-1, 1):
	with ck.part("soft_stalk_" + ("l" if s < 0 else "r"), hinge=(s * 0.06, -0.68, 0.6)):
		stalk = ck.bezier((s * 0.06, -0.68, 0.56), (s * 0.08, -0.72, 0.78), (s * 0.15, -0.84, 0.88), n=7)
		ck.limb(f"stalk{s}", stalk, 0.04, 0.025, skin, sides=8)
		for k in (2, 4):  # little wrinkle rings on the stalks
			ck.limb(f"wrinkle{s}{k}", [stalk[k] - (stalk[k + 1] - stalk[k]) * 0.1, stalk[k] + (stalk[k + 1] - stalk[k]) * 0.1], 0.037, 0.035, skin, sides=8, subsurf=0)
		ck.blob((s * 0.155, -0.85, 0.89), (0.045, 0.045, 0.045), tip, seed=5, jitter=0.02)     # dark eye bulb
		ck.blob((s * 0.16, -0.885, 0.895), (0.028, 0.02, 0.028), eye, seed=6, jitter=0.02)     # the glowing eye

# ---- the shell: a coil that shrinks as it winds inward (a logarithmic spiral), seen from the side.
C = Vector((0.03, 0.06, 0.8))
K = 0.18                  # how fast the coil shrinks
R0 = 0.37
r0 = R0 * (1 - math.exp(-2 * math.pi * K)) / (1 + math.exp(-2 * math.pi * K))  # whorls just touch
WIDE = 2.15               # the tube is wider than it is deep: a fat, heavy shell
turns = 2.5
steps = int(turns * 40)


def coil(th, grow=1.0):
	f = math.exp(-K * th)
	phi = math.radians(-112) + th
	lean = (1 - f) * 0.14  # the coil leans a little to one side, like a real snail
	return C + Vector((lean, math.cos(phi) * R0 * f, math.sin(phi) * R0 * f)), r0 * f * grow, lean


rings = []
for i in range(steps + 1):
	th = i / steps * turns * 2 * math.pi
	p, r, _ = coil(th)
	rings.append((p, r, r * WIDE))  # (radial depth, sideways width) for a ring lofted with up = X
ck.loft("shell", rings, shell_mat, sides=18, caps=(False, True), up=Vector((1, 0, 0)), subsurf=0)
# Growth ridges along the coil (darker stone, standing a little proud).
for i in range(5, steps - 10, 8):
	th0 = i / steps * turns * 2 * math.pi
	seg = []
	for d, g in ((-0.05, 1.0), (0.0, 1.08), (0.05, 1.0)):
		p, r, _ = coil(th0 + d, g)
		seg.append((p, r, r * WIDE * (0.99 + (g - 1) * 0.5)))
	ck.loft(f"ridge{i}", seg, shell_dark, sides=18, caps=(False, False), up=Vector((1, 0, 0)), subsurf=0)
# The mouth: a thick, dark rim.
lip = []
for d in (-0.015, 0.06):
	p, r, _ = coil(d, 1.1)
	lip.append((p, r, r * WIDE * 1.05))
ck.loft("rim", lip, shell_dark, sides=18, up=Vector((1, 0, 0)), subsurf=0)

# Hiding: only two small eyes peek out of the shell's mouth (the game shows these when it hides).
p0, r_m, _ = coil(0.0)
p1, _, _ = coil(0.06)
out_dir = (p0 - p1).normalized()
with ck.part("peek", hinge=tuple(p0)):
	for s in (-1, 1):
		base = p0 + Vector((s * 0.07, 0, r_m * 0.55))
		tipp = base + out_dir * 0.1 + Vector((s * 0.03, 0, 0.09))
		ck.limb(f"peekstalk{s}", [base, base.lerp(tipp, 0.5) + Vector((0, 0, 0.01)), tipp], 0.025, 0.016, skin, sides=7)
		ck.blob(tuple(tipp), (0.03, 0.03, 0.03), tip, seed=8, jitter=0.02)
		ck.blob(tuple(tipp + out_dir * 0.02), (0.018, 0.014, 0.018), eye, seed=9, jitter=0.02)

# Moss sitting in the dips on top of the shell, and pebbles stuck to its sides (a ROCK snail).
for k in range(int(80 * MOSS)):
	th = rnd.uniform(1.4, 4.6)
	p, r, lean = coil(th)
	n = (p - (C + Vector((lean, 0, 0)))).normalized()
	if n.z < 0.1:
		continue
	a = math.radians(rnd.uniform(35, 145))  # around the tube's cross-section (an oval)
	at = p + Vector((math.cos(a) * r * WIDE * 0.97, 0, 0)) + n * math.sin(a) * r * 0.97
	ck.blob(tuple(at), (rnd.uniform(0.025, 0.05), rnd.uniform(0.025, 0.05), 0.014), moss if k % 4 else moss_lite, seed=k + 20, jitter=0.4, detail=1, subsurf=0)
PEBBLES = [ck.skin("pebble_light", tile=0.25, rough=0.55), ck.skin("pebble_warm", tile=0.25, rough=0.55), shell_dark]
for k in range(STONES):
	th = rnd.uniform(0.5, 3.8)
	p, r, _ = coil(th)
	side = rnd.choice((-1, 1))
	a = math.radians(rnd.uniform(-25, 25))
	n = (p - (C + Vector((coil(th)[2], 0, 0)))).normalized()
	at = p + Vector((side * math.cos(a) * r * WIDE * 0.95, 0, 0)) + n * math.sin(a) * r * 0.95
	sz = rnd.uniform(0.035, 0.07)
	kit.gem(tuple(at), (sz, sz * rnd.uniform(0.8, 1.2), sz * 0.8), rnd.choice(PEBBLES), seed=k + 40)
if CRYSTAL:  # a cluster of violet crystal growing out of the top of its shell
	gem = ck.color("snail_gem", (0.6, 0.38, 0.95), rough=0.15, glow=0.6)
	p, r, lean = coil(3.2)
	n = (p - (C + Vector((lean, 0, 0)))).normalized()
	base = p + n * r * 0.85
	for c in range(6):
		kit.crystal(tuple(base + Vector((rnd.uniform(-0.05, 0.05), rnd.uniform(-0.04, 0.04), 0))), rnd.uniform(0.02, 0.035),
			rnd.uniform(0.09, 0.2), gem, tilt=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), rnd.uniform(0, 360)))

ck.save(out, preview)
