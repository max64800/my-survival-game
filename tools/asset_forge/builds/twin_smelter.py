# Twin Smelter (folder: stations): left a charcoal kiln (log pile beside it, iron-banded chimney), right an ore smelter (copper chimney), joined by a low arched stone wall at the back.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

top = _parts.dome(-0.62, 0, r=0.58, h=0.85, kind="kiln")
_parts.chimney(-0.62, 0, top - 0.02, r=0.18, h=0.3, copper=False)
top = _parts.dome(0.62, 0, kind="smelter")
_parts.chimney(0.62, 0, top - 0.02)
# Low joining wall behind the gap, with a copper plate.
for k in range(3):
	kit.stone((0.36, 0.3, 0.2), (0, 0.22, 0.1 + k * 0.2))
kit.stone((0.5, 0.34, 0.12), (0, 0.22, 0.66))
kit.tbox("copper", (0.2, 0.03, 0.18), (0, 0.06, 0.45), bevel=0.008)
_parts.log_pile(-1.55, 0.0, n_bottom=3, length=0.55)

kit.save(out, preview)
