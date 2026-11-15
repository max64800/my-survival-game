# Crystal Sconce (folder: stations): a stone wall plate with a forged iron arm and cup holding a glowing amber crystal cluster.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

kit.stone((0.32, 0.08, 0.6), (0, 0.16, 0.5))
iron = kit.tex_mat("iron")
kit.tbox("iron", (0.12, 0.04, 0.42), (0, 0.11, 0.5))
kit.rivet((0, 0.09, 0.66), iron, r=0.025)
kit.rivet((0, 0.09, 0.34), iron, r=0.025)
kit.tcyl("iron", 0.025, 0.2, (0, 0.02, 0.45), rot=(90, 0, 0), verts=8)
kit.tcyl("iron", 0.022, 0.12, (0, -0.08, 0.5), verts=8)
kit.cone(0.12, 0.06, 0.08, (0, -0.1, 0.57), iron, verts=12)
kit.ring(0.12, 0.015, (0, -0.1, 0.61), iron, seg=14)
kit.crystal_cluster((0, -0.1, 0.6), 0.9, kit.glow("crystal_amber", 0.45), seed=4, n=6)

kit.save(out, preview)
