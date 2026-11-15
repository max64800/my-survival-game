# Campfire (folder: stations): a ring of stones around a teepee of straight logs and glowing coals; the game plays animated flames at its fire spot.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

_parts.fire_pit(0, 0, r=0.45, stones=10, flames=1.0)

kit.save(out, preview)
