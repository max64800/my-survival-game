"""Builds every hand-made creature (by Claude 3).

    python tools/asset_forge/build_creatures.py <game folder>/assets/models [only=rock_beetle] [previews=<folder>]

Creatures rebuilt to match the approved pictures (Nov 15) come in 4 looks on one body:
    creatures/<kind>_<mossy|frost|ember|spore>.glb   (the game picks the look from the monster's variant)
Older Nov 14 creatures not rebuilt yet come in individual versions:
    monsters/<kind>_v<N>.glb
Needs Blender (BLENDER env var, or the default install).
"""
import glob
import os
import shutil
import subprocess
import tempfile

import glb_jpeg_fix
import glb_scale
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOOKS = ["mossy", "frost", "ember", "spore"]

# kind: (build script, "looks" or number of versions, extra words)
CREATURES = {
	"rock_beetle": ("monster_rock_beetle", "looks", []),
	"rock_snail": ("monster_rock_snail", "looks", []),  # Nov 17 rebuild; frost, ember and spore looks Nov 18
	"cave_bat": ("monster_cave_bat", "looks", []),  # Nov 18 rebuild; frost, ember and spore looks Nov 18
}


# Looks that go through the sculpt-and-bake pass (docs/art/CREATURE-RECIPE.md) after the grey build.
# Creatures that go through the sculpt-and-bake pass (docs/art/CREATURE-RECIPE.md) after the grey build, every look.
SCULPTED = {"rock_beetle": "sculpt_test_beetle.py"}
# The game's size for the finished model (the baked beetle is 1.54 m long; the game's beetle and its collision ~1.36 m).
GAME_SCALE = {"rock_beetle": 0.88, "rock_snail": 0.88, "cave_bat": 0.85}  # (bat: 1.74 m wing tip to wing tip -> 1.48 m)


def blender():
	if os.environ.get("BLENDER"):
		return os.environ["BLENDER"]
	hits = sorted(glob.glob("C:/Program Files/Blender Foundation/Blender*/blender.exe"))
	return hits[-1] if hits else (shutil.which("blender") or sys.exit("Blender not found"))


def main():
	if len(sys.argv) < 2:
		sys.exit(__doc__)
	models = Path(sys.argv[1])
	only = next((a[5:] for a in sys.argv[2:] if a.startswith("only=")), None)
	prev = next((a[9:] for a in sys.argv[2:] if a.startswith("previews=")), None)
	for kind, (script, versions, extra) in CREATURES.items():
		if only and kind != only:
			continue
		looks = LOOKS if versions == "looks" else versions if isinstance(versions, list) else None
		jobs = [(models / "creatures" / f"{kind}_{look}.glb", [f"look={look}"]) for look in looks] if looks else \
			[(models / "monsters" / f"{kind}_v{v}.glb", [f"v={v}"]) for v in range(versions)]
		for glb, words in jobs:
			glb.parent.mkdir(parents=True, exist_ok=True)
			args = [blender(), "--background", "--factory-startup", "--python", str(HERE / "builds" / f"{script}.py"), "--", str(glb)]
			args.append(str(Path(prev) / f"{glb.stem}.png") if prev else "")
			args += extra + words
			res = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
			done = [line for line in res.stdout.splitlines() if line.startswith("KIT_DONE")]
			if done and kind in SCULPTED:  # sculpt, paint and bake the grey model into the finished one
				with tempfile.TemporaryDirectory() as tmp:
					sc = subprocess.run([blender(), "--background", "--factory-startup", "--python", str(HERE / SCULPTED[kind]),
						"--", str(glb), tmp] + words, capture_output=True, text=True, encoding="utf-8", errors="replace")
					if (Path(tmp) / "test.glb").exists():
						shutil.copy(Path(tmp) / "test.glb", glb)
						glb_jpeg_fix.fix(str(glb))  # (the sculpt pass already did; harmless twice)
						glb_scale.set_scale(glb, GAME_SCALE.get(kind, 1.0))
						print(f"  sculpted + baked {glb.name}")
					else:
						print(f"SCULPT FAILED {glb.name}:\n{sc.stdout[-1500:]}\n{sc.stderr[-1500:]}")
			if done and kind not in SCULPTED and GAME_SCALE.get(kind, 1.0) != 1.0:  # (the snail sculpts and bakes in its own build)
				glb_scale.set_scale(glb, GAME_SCALE[kind])
			print(done[0].replace(str(glb), glb.name) if done else f"FAILED {glb.name}:\n{res.stdout[-1500:]}\n{res.stderr[-1500:]}")


if __name__ == "__main__":
	main()
