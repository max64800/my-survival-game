# Smelter (folder: stations): a stone dome with a copper-banded chimney, flames and a glowing crucible in its mouth.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

top = _parts.dome(0, 0, kind="smelter")
_parts.chimney(0, 0, top - 0.02)

kit.save(out, preview)
