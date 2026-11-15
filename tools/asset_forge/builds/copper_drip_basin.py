# Copper Drip Basin (folder: stations): a riveted copper basin of still water with ripples under a falling drop.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

kit.tcyl("copper", 0.48, 0.24, (0, 0, 0.12), verts=24)
kit.ring(0.48, 0.035, (0, 0, 0.3), kit.tex_mat("copper", "dark"), seg=28)
kit.ring(0.46, 0.03, (0, 0, 0.27), kit.tex_mat("copper", "b"), seg=28)
kit.ring(0.485, 0.02, (0, 0, 0.08), kit.tex_mat("copper", "dark"), seg=28)
kit.water((0, 0, 0.25), 0.44, ripples=3)
for k in range(12):
	a = 2 * math.pi * k / 12
	kit.rivet((math.cos(a) * 0.49, math.sin(a) * 0.49, 0.19), r=0.017)
kit.drop((0.03, 0.0, 0.62), 1.2)

kit.save(out, preview)
