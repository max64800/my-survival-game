"""Build hand-made models and keep the journey copies.

    python build_hand.py workbench smelter        (any Python)

For each name: runs tools/asset_forge/builds/<name>.py in Blender, writes
    assets/models/<folder>/<name>.glb                 (what the game loads)
    journey/3d/v2_hand_built/<folder>/<name>.glb/.png (the "after" for videos)
and copies the concept picture it was built from (<AI3D_HOME>/work/crops/<name>.png) as <name>_concept.png.
The AI-made "before" versions are already in journey/3d/v1_ai_triposr/.
"""
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parent.parent
AI3D = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d"))


def blender():
	if os.environ.get("BLENDER"):
		return os.environ["BLENDER"]
	hits = sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender*\blender.exe"))
	return hits[-1] if hits else (shutil.which("blender") or sys.exit("Blender not found"))


def folder_of(name):
	first = (HERE / "builds" / f"{name}.py").read_text(encoding="utf-8").splitlines()[0]
	return "items" if "folder: items" in first else "stations"


def main():
	for name in sys.argv[1:]:
		folder = folder_of(name)
		out = GAME / "assets" / "models" / folder / f"{name}.glb"
		jdir = GAME / "journey" / "3d" / "v2_hand_built" / folder
		jdir.mkdir(parents=True, exist_ok=True)
		res = subprocess.run([blender(), "--background", "--factory-startup", "--python", str(HERE / "builds" / f"{name}.py"),
			"--", str(out), str(jdir / f"{name}.png")], capture_output=True, text=True, encoding="utf-8", errors="replace")
		done = [l for l in res.stdout.splitlines() if l.startswith("KIT_DONE")]
		if not done:
			print(f"FAILED {name}:\n{res.stdout[-2000:]}\n{res.stderr[-2000:]}")
			continue
		shutil.copy(out, jdir / f"{name}.glb")
		concept = AI3D / "work" / "crops" / f"{name}.png"
		if concept.exists():
			shutil.copy(concept, jdir / f"{name}_concept.png")
		print(done[0].replace(str(out), f"{folder}/{name}.glb"))


if __name__ == "__main__":
	main()
