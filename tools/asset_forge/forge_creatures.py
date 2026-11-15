"""The whole creature chain, for all 3 creatures x 4 variants (by Claude 3).

    <AI3D_HOME>/venv-web/Scripts/python tools/asset_forge/forge_creatures.py [only=rock_beetle] [skip_forge] [previews=<folder>]

1. creature_sources.py: one picture per variant (from assets/concepts/creatures/), background removed
2. forge.py: picture -> 3D statue. Uses the TRELLIS website (best) when a free Hugging Face key is in
   <AI3D_HOME>/hf_token.txt (never in this repo); otherwise TripoSR on this PC.
3. creature_forge.py (Blender): paints the face from the picture, corrects the colours, faces it forward,
   splits it into moving parts -> assets/models/creatures/<creature>_<variant>.glb
"""
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
AI3D = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d"))
WORK = AI3D / "work" / "creatures"
CREATURES = {"rock_snail": "snail", "cave_bat": "bat", "rock_beetle": "beetle"}
VARIANTS = ["mossy", "frost", "ember", "spore"]


def blender():
	if os.environ.get("BLENDER"):
		return os.environ["BLENDER"]
	hits = sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender*\blender.exe"))
	return hits[-1] if hits else (shutil.which("blender") or sys.exit("Blender not found"))


def main():
	args = sys.argv[1:]
	only = next((a[5:] for a in args if a.startswith("only=")), None)
	prev = next((a[9:] for a in args if a.startswith("previews=")), None)
	env = dict(os.environ, PYTHONIOENCODING="utf-8")
	token = AI3D / "hf_token.txt"
	engine = "triposr"
	if token.exists() and token.read_text().strip():
		env["HF_TOKEN"] = token.read_text().strip()
		engine = "trellis"
	if "skip_forge" not in args:
		subprocess.run([sys.executable, str(HERE / "creature_sources.py")], env=env, check=True)
	out_dir = GAME / "assets" / "models" / "creatures"
	out_dir.mkdir(parents=True, exist_ok=True)
	for c, kind in CREATURES.items():
		if only and c != only:
			continue
		for v in VARIANTS:
			name = f"{c}_{v}"
			forged = WORK / "forged" / f"{name}.glb"  # the forge's raw statue (a working file, not a game file)
			if "skip_forge" not in args or not forged.exists():
				r = subprocess.run([sys.executable, str(HERE / "forge.py"), str(WORK / f"{name}.png"), "--name", name,
					"--kind", "big", "--size", "1.4", "--tris", "24000", "--engine", engine], env=env, capture_output=True, text=True)
				if r.returncode != 0 and engine == "trellis":  # website busy or out of time: use this PC
					subprocess.run([sys.executable, str(HERE / "forge.py"), str(WORK / f"{name}.png"), "--name", name,
						"--kind", "big", "--size", "1.4", "--tris", "24000", "--engine", "triposr"], env=env, capture_output=True)
				made = GAME / "assets" / "models" / "bigs" / f"{name}.glb"
				if made.exists():
					forged.parent.mkdir(parents=True, exist_ok=True)
					shutil.move(str(made), str(forged))
					for extra in made.parent.glob(f"{name}.glb.import"):
						extra.unlink()
			pv = str(Path(prev) / name) if prev else ""
			r = subprocess.run([blender(), "--background", "--factory-startup", "--python", str(HERE / "creature_forge.py"), "--",
				str(forged), str(WORK / f"{name}_cut.png"), kind, str(out_dir / f"{name}.glb"), pv], capture_output=True, text=True,
				encoding="utf-8", errors="replace")
			lines = [line for line in r.stdout.splitlines() if line.startswith("CF ")]
			print(name, "->", lines[-1] if lines else "FAILED\n" + r.stdout[-1500:] + r.stderr[-1500:])


if __name__ == "__main__":
	main()
