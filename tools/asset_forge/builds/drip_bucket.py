# Drip Bucket (folder: stations): a wooden bucket with iron hoops and a handle, full of clear water.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

kit.tcyl("wood", 0.3, 0.34, (0, 0, 0.17), verts=14)
kit.ring(0.28, 0.035, (0, 0, 0.37), kit.tex_mat("wood", "c"), seg=24)
for z in (0.08, 0.3):
	kit.ring(0.305, 0.022, (0, 0, z), kit.tex_mat("iron"), seg=24)
kit.water((0, 0, 0.355), 0.27, ripples=2)
kit.ring(0.3, 0.012, (0, 0, 0.42), kit.tex_mat("iron"), rot=(90, 0, 0), seg=20).scale = (1, 1, 0.6)

kit.save(out, preview)
