"""Asset forge: picture -> 3D model -> cleaned up -> in the game's assets folder.

Usage (run with the small "venv-web" Python, see tools/asset_forge/README.md):
    python forge.py picture.png --name workbench --kind station
    python forge.py mushroom.png --name glowcap --kind prop --engine triposr

Engines (both free):
    trellis  = Microsoft TRELLIS.2 on the free Hugging Face website (best quality, a few per day)
    triposr  = TripoSR on this PC (fast, rougher, unlimited)

Settings come from environment variables so no personal paths live in this public repo:
    AI3D_HOME  folder holding venv/ and TripoSR/   (default: ~/ai3d)
    BLENDER    path to blender.exe                  (default: searched in Program Files)
    HF_TOKEN   optional free Hugging Face token (more daily website quota)
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parent.parent
AI3D = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d"))

# Size presets: (largest side in meters, triangle budget, texture pixels)
KINDS = {
	"item": (0.4, 800, 128),      # things you hold or drop: a mug, a gem
	"prop": (1.0, 2500, 256),     # decorations: mushroom, barrel, rock
	"station": (1.6, 6000, 256),  # workbench, furnace, anvil
	"big": (3.5, 10000, 512),     # statues, big ruins, monsters
}


# TripoSR saves models lying on their back; this stands them up. (--raw keeps the --engine turn.)
ENGINE_TURN_X = {"triposr": -90.0, "trellis": 0.0}


def find_blender():
	if os.environ.get("BLENDER"):
		return os.environ["BLENDER"]
	hits = sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender*\blender.exe"))
	if hits:
		return hits[-1]
	found = shutil.which("blender")
	if found:
		return found
	sys.exit("Blender not found. Install it or set BLENDER to blender.exe")


def run_triposr(image, work):
	repo = AI3D / "TripoSR"
	out = work / "triposr"
	py = AI3D / "venv" / "Scripts" / "python.exe"
	if not py.exists():
		py = AI3D / "venv" / "bin" / "python"
	cmd = [str(py), str(repo / "run.py"), str(image), "--output-dir", str(out),
		"--model-save-format", "glb", "--mc-resolution", "256"]
	subprocess.run(cmd, cwd=repo, check=True)
	return out / "0" / "mesh.glb"


def cut_out(image, work):
	"""Remove the background on this PC (rembg + ISNet, MIT / Apache-2.0).

	The website would otherwise use its own background remover, whose licence is not free for
	games we sell. A see-through background makes the website skip that step.
	"""
	from PIL import Image
	from rembg import new_session, remove
	out = work / "cutout.png"
	img = Image.open(image).convert("RGBA")
	alpha = img.getchannel("A")
	if alpha.getextrema()[0] == 255:  # no see-through pixels yet
		# Name the cutter on purpose: rembg's default (BRIA RMBG) is not free for games we sell.
		img = remove(img, session=new_session("isnet-general-use"))
	img.save(out)
	return out


def run_trellis(image, work, seed):
	from gradio_client import Client, handle_file
	cut = cut_out(image, work)
	client = Client("microsoft/TRELLIS.2", token=os.environ.get("HF_TOKEN") or None)
	print("Website connected. Sending the cut-out picture...")
	client.predict(api_name="/start_session")
	clean = client.predict(handle_file(str(cut)), api_name="/preprocess_image")
	print("Making the 3D shape (this can take a minute or two)...")
	client.predict(
		handle_file(clean), seed, "1024",
		7.5, 0.7, 12, 5.0,
		7.5, 0.5, 12, 3.0,
		1.0, 0.0, 12, 3.0,
		api_name="/image_to_3d",
	)
	print("Downloading the model...")
	glb, _ = client.predict(100000, 1024, api_name="/extract_glb")
	dst = work / "trellis.glb"
	shutil.copy(glb, dst)
	return dst


def cleanup(raw, dst, preview, a):
	size, tris, tex = KINDS[a.kind]
	cmd = [find_blender(), "--background", "--factory-startup", "--python", str(HERE / "blender_cleanup.py"), "--",
		str(raw), str(dst), "--size", str(a.size or size), "--tris", str(a.tris or tris), "--tex", str(tex),
		"--rotate-x", str(a.rotate_x + ENGINE_TURN_X[a.engine]), "--rotate-z", str(a.rotate_z), "--fit", a.fit, "--preview", str(preview)]
	res = subprocess.run(cmd, capture_output=True, text=True)
	for line in res.stdout.splitlines():
		if line.startswith("FORGE_REPORT "):
			return json.loads(line[len("FORGE_REPORT "):])
	print(res.stdout[-3000:], res.stderr[-3000:])
	sys.exit("Blender cleanup failed (see above).")


def main():
	p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	p.add_argument("image")
	p.add_argument("--name", required=True, help="file name, e.g. workbench")
	p.add_argument("--kind", choices=KINDS, default="prop")
	p.add_argument("--engine", choices=["trellis", "triposr"], default="trellis")
	p.add_argument("--size", type=float, help="override size in meters")
	p.add_argument("--fit", choices=["largest", "height"], default="largest")
	p.add_argument("--tris", type=int, help="override triangle budget")
	p.add_argument("--rotate-x", type=float, default=0.0)
	p.add_argument("--rotate-z", type=float, default=0.0)
	p.add_argument("--seed", type=int, default=0)
	p.add_argument("--raw", help="skip step 1 and clean this existing model instead (give --engine it came from)")
	a = p.parse_args()

	image = Path(a.image).resolve()
	work = AI3D / "work" / f"{a.name}_{time.strftime('%Y%m%d_%H%M%S')}"
	work.mkdir(parents=True, exist_ok=True)
	if image.exists():
		shutil.copy(image, work / ("input" + image.suffix))

	t0 = time.time()
	if a.raw:
		raw = Path(a.raw).resolve()
	elif a.engine == "trellis":
		raw = run_trellis(image, work, a.seed)
	else:
		raw = run_triposr(image, work)
	print(f"Step 1 done ({time.time() - t0:.0f} s): {raw}")

	dst_dir = GAME / "assets" / "models" / f"{a.kind}s"
	dst_dir.mkdir(parents=True, exist_ok=True)
	dst = dst_dir / f"{a.name}.glb"
	preview = work / "preview.png"
	report = cleanup(raw, dst, preview, a)
	report.update({"engine": "raw" if a.raw else a.engine, "preview": str(preview), "work": str(work)})
	print("FORGE DONE " + json.dumps(report, indent=1))


if __name__ == "__main__":
	main()
