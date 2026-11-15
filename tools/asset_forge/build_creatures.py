"""Builds every hand-made creature and all its individual versions (by Claude 3).

    python tools/asset_forge/build_creatures.py <game folder>/assets/models/monsters [only=rock_beetle] [previews=<folder>]

Writes <kind>_v<N>.glb for each version; the game picks one per creature (MonsterModel.build).
Needs Blender (BLENDER env var, or the default install). Textures: run creature_textures.py first.
"""
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

# kind: (build script, versions, extra words)
CREATURES = {
	"rock_snail": ("monster_rock_snail", 3, []),
	"cave_bat": ("monster_cave_bat", 4, []),
	"rock_beetle": ("monster_rock_beetle", 4, []),
	"great_rock_beetle": ("monster_rock_beetle", 4, ["great"]),
}


def blender():
	if os.environ.get("BLENDER"):
		return os.environ["BLENDER"]
	hits = sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender*\blender.exe"))
	return hits[-1] if hits else (shutil.which("blender") or sys.exit("Blender not found"))


def main():
	if len(sys.argv) < 2:
		sys.exit(__doc__)
	out = Path(sys.argv[1])
	out.mkdir(parents=True, exist_ok=True)
	only = next((a[5:] for a in sys.argv[2:] if a.startswith("only=")), None)
	prev = next((a[9:] for a in sys.argv[2:] if a.startswith("previews=")), None)
	for kind, (script, versions, extra) in CREATURES.items():
		if only and kind != only:
			continue
		for v in range(versions):
			glb = out / f"{kind}_v{v}.glb"
			args = [blender(), "--background", "--factory-startup", "--python", str(HERE / "builds" / f"{script}.py"), "--", str(glb)]
			args.append(str(Path(prev) / f"{kind}_v{v}.png") if prev else "")
			args += extra + [f"v={v}"]
			res = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
			done = [line for line in res.stdout.splitlines() if line.startswith("KIT_DONE")]
			print(done[0].replace(str(glb), glb.name) if done else f"FAILED {glb.name}:\n{res.stdout[-1500:]}\n{res.stderr[-1500:]}")


if __name__ == "__main__":
	main()
