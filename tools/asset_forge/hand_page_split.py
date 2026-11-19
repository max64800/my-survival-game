"""Split a recorded dwarf (.glb from dwarf_anim_export.gd hands=1) into the body and its moves, for the close-up
hands page (dwarf-animations Claude, Nov 19, 2026). The page host serves files up to ~14 MB: one tool's recording is
~24 MB (half moves, half body and pictures), so the page loads ONE body file and one small moves file per tool, and
plays each tool's moves on the same body (the bones have the same names in every file).

    python -I tools/asset_forge/hand_page_split.py body  in.glb out.glb   (meshes, skins, pictures; no moves)
    python -I tools/asset_forge/hand_page_split.py moves in.glb out.glb   (bones and moves only)

Then shrink each with dwarf_page_copy.py (pictures, every 2nd frame) into the page's glTF text. A moves channel whose
every key equals the bone's own resting value is left out (it changes nothing).
"""
import json
import struct
import sys

CT = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
DEFAULT = {"translation": [0, 0, 0], "rotation": [0, 0, 0, 1], "scale": [1, 1, 1]}


def read_glb(path):
	data = open(path, "rb").read()
	n = struct.unpack_from("<I", data, 12)[0]
	js = json.loads(data[20:20 + n])
	off = 20 + n
	bn = struct.unpack_from("<I", data, off)[0]
	return js, data[off + 8:off + 8 + bn]


def write_glb(path, js, blob):
	text = json.dumps(js, separators=(",", ":")).encode()
	text += b" " * ((4 - len(text) % 4) % 4)
	blob += b"\0" * ((4 - len(blob) % 4) % 4)
	out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(text) + 8 + len(blob))
	out += struct.pack("<II", len(text), 0x4E4F534A) + text + struct.pack("<II", len(blob), 0x004E4942) + blob
	open(path, "wb").write(out)


def values(js, blob, i):
	a = js["accessors"][i]
	v = js["bufferViews"][a["bufferView"]]
	nc = NC[a["type"]]
	st = v.get("byteStride", 4 * nc)
	start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
	return [struct.unpack_from("<%df" % nc, blob, start + k * st) for k in range(a["count"])]


def main():
	mode, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
	js, blob = read_glb(src)
	if mode == "body":
		js["animations"] = []
	else:
		for nd in js["nodes"]:
			nd.pop("mesh", None)
			nd.pop("skin", None)
		for k in ["meshes", "skins", "materials", "textures", "images", "samplers"]:
			js.pop(k, None)
		kept = 0
		for an in js.get("animations", []):
			chans = []
			for ch in an["channels"]:
				node = js["nodes"][ch["target"]["node"]]
				path = ch["target"]["path"]
				rest = node.get(path, DEFAULT[path])
				out = values(js, blob, an["samplers"][ch["sampler"]]["output"])
				if all(max(abs(x - r) for x, r in zip(v, rest)) < 1e-5 for v in out):
					continue
				chans.append(ch)
			samplers = []  # (only the samplers still used: the page copy keeps every sampler's numbers)
			for ch in chans:
				samplers.append(an["samplers"][ch["sampler"]])
				ch["sampler"] = len(samplers) - 1
			an["channels"] = chans
			an["samplers"] = samplers
			kept += len(chans)
		print("kept", kept, "channels")
	write_glb(dst, js, blob)


main()
