# Chest (folder: stations): a plank chest with iron straps and a rounded lid.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

_parts.chest("wood", "iron")

kit.save(out, preview)
