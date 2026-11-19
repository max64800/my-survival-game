# A lighter copy of a recorded dwarf (.glb from dwarf_anim_export.gd) for the "Dwarf Body" 3D page (Claude, Nov 18, 2026).
#
#   python tools/asset_forge/dwarf_page_copy.py <in.glb> <out.json> [size=512] [every=2] [nrm=<bump picture size>] [drop=<part>,<part>] [nocolor=1] [big=<picture>:<size>]
#
# The page host serves files up to ~14.6 MB and no .glb, so the page reads glTF text with everything inside it.
# This copy has pictures at most `size` pixels, keeps every `every`-th animation frame, and leaves out the bump
# directions (TANGENT: the page works them out). drop: parts hidden anyway (e.g. the foot wraps inside boots) are left
# out (names containing these words). Needs Pillow.
import base64
import io
import json
import struct
import sys

from PIL import Image

CT = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path):
	data = open(path, "rb").read()
	n = struct.unpack_from("<I", data, 12)[0]
	js = json.loads(data[20:20 + n])
	off = 20 + n
	bn = struct.unpack_from("<I", data, off)[0]
	return js, data[off + 8:off + 8 + bn]


def main():
	src, out = sys.argv[1], sys.argv[2]
	opts = dict(a.split("=") for a in sys.argv[3:])
	size, every = int(opts.get("size", 512)), int(opts.get("every", 2))
	nsize = int(opts.get("nrm", size))
	squeeze_kinds = opts.get("squeeze", "WEIGHTS_0,JOINTS_0,TEXCOORD_0").split(",")
	js, binary = read_glb(src)
	views, accs = js["bufferViews"], js["accessors"]

	def acc_bytes(i):
		a = accs[i]
		v = views[a["bufferView"]]
		st = v.get("byteStride", CT[a["componentType"]] * NC[a["type"]])
		start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
		w = CT[a["componentType"]] * NC[a["type"]]
		return [binary[start + k * st:start + k * st + w] for k in range(a["count"])]

	new_acc, chunks, strides = [], [], []  # each kept accessor gets its own packed view (stride when padded)

	def keep(i, rows=None):
		a = dict(accs[i])
		items = acc_bytes(i)
		if rows is not None:
			items = [items[k] for k in rows]
			a["count"] = len(items)
			if "min" in a:
				vals = [struct.unpack("<" + "f" * NC[a["type"]], b) for b in items] if a["componentType"] == 5126 else None
				if vals:
					a["min"] = [min(v[c] for v in vals) for c in range(len(vals[0]))]
					a["max"] = [max(v[c] for v in vals) for c in range(len(vals[0]))]
		a.pop("byteOffset", None)
		a["bufferView"] = len(chunks)
		chunks.append(b"".join(items))
		strides.append(0)
		new_acc.append(a)
		return len(new_acc) - 1

	remap = {}

	def once(i, kind=None):
		if i not in remap:
			remap[i] = squeeze(i, kind) if kind else keep(i)
		return remap[i]

	def small_indices(i):
		"""Triangle corner numbers as 2-byte numbers when every part has fewer than 65536 points (they were 4 bytes)."""
		a = accs[i]
		if a["componentType"] != 5125:
			return once(i)
		vals = struct.unpack("<%dI" % a["count"], b"".join(acc_bytes(i)))
		if max(vals) > 65535:
			return once(i)
		b = dict(a)
		b.pop("byteOffset", None)
		b["componentType"] = 5123
		b["bufferView"] = len(chunks)
		chunks.append(struct.pack("<%dH" % len(vals), *vals))
		strides.append(0)
		new_acc.append(b)
		return len(new_acc) - 1

	def squeeze(i, kind):
		"""Points stored compactly (KHR_mesh_quantization, which three.js reads): bone weights and picture positions
		as whole numbers 0..255 / 0..65535, surface directions as -127..127, bone numbers as bytes."""
		a = accs[i]
		if kind not in squeeze_kinds:
			return keep(i)
		rows = acc_bytes(i)
		nc = NC[a["type"]]
		if kind == "JOINTS_0" and a["componentType"] in (5121, 5123):
			fmt = "<" + ("B" if a["componentType"] == 5121 else "H") * nc
			vals = [struct.unpack(fmt, r) for r in rows]
			if max(max(v) for v in vals) > 255:
				return keep(i)
			out, ct, norm, pad = b"".join(struct.pack("<4B", *v) for v in vals), 5121, False, 0
		elif a["componentType"] != 5126:
			return keep(i)
		else:
			vals = [struct.unpack("<" + "f" * nc, r) for r in rows]
			if kind == "WEIGHTS_0":
				out = b""
				for v in vals:
					q = [max(0, min(255, round(x * 255))) for x in v]
					q[q.index(max(q))] += 255 - sum(q)  # (they still add up to 1)
					out += struct.pack("<4B", *q)
				ct, norm, pad = 5121, True, 0
			elif kind == "NORMAL":
				out = b"".join(struct.pack("<3bx", *[max(-127, min(127, round(x * 127))) for x in v]) for v in vals)
				ct, norm, pad = 5120, True, 4
			elif kind == "TEXCOORD_0" and all(-0.001 <= x <= 1.001 for v in vals for x in v):
				out = b"".join(struct.pack("<2H", *[max(0, min(65535, round(x * 65535))) for x in v]) for v in vals)
				ct, norm, pad = 5123, True, 0
			else:
				return keep(i)
		b = dict(a)
		b.pop("byteOffset", None)
		b.pop("min", None)
		b.pop("max", None)
		b["componentType"], b["normalized"] = ct, norm
		if kind == "JOINTS_0":
			b.pop("normalized")
		b["bufferView"] = len(chunks)
		chunks.append(out)
		strides.append(pad)
		new_acc.append(b)
		js.setdefault("extensionsUsed", []).count("KHR_mesh_quantization") or js["extensionsUsed"].append("KHR_mesh_quantization")
		js.setdefault("extensionsRequired", []).count("KHR_mesh_quantization") or js["extensionsRequired"].append("KHR_mesh_quantization")
		return len(new_acc) - 1

	drop = [w for w in opts.get("drop", "").split(",") if w]
	used = set()
	for nd in js.get("nodes", []):
		if "mesh" in nd:
			if any(w in js["meshes"][nd["mesh"]].get("name", "") for w in drop):
				del nd["mesh"]
				nd.pop("skin", None)
			else:
				used.add(nd["mesh"])
	for mi, m in enumerate(js.get("meshes", [])):
		if mi not in used:
			m["primitives"] = [{"attributes": {"POSITION": m["primitives"][0]["attributes"]["POSITION"]}}]
		for p in m["primitives"]:
			p["attributes"].pop("TANGENT", None)
			if "nocolor" in opts:
				p["attributes"].pop("COLOR_0", None)  # (plain white per-point colours: no change on the page)
			p["attributes"] = {k: once(v, k if k in ("NORMAL", "WEIGHTS_0", "JOINTS_0", "TEXCOORD_0") else None) for k, v in p["attributes"].items()}
			if "indices" in p:
				p["indices"] = small_indices(p["indices"])
	for s in js.get("skins", []):
		if "inverseBindMatrices" in s:
			s["inverseBindMatrices"] = once(s["inverseBindMatrices"])
	times = {}  # (one copy of each clip's frame times, shared by all its tracks)
	for an in js.get("animations", []):
		for smp in an["samplers"]:
			n = accs[smp["input"]]["count"]
			rows = list(range(0, n, every))
			if rows[-1] != n - 1:
				rows.append(n - 1)  # (the last frame stays, so the loop closes)
			if smp["input"] not in times:
				times[smp["input"]] = keep(smp["input"], rows)
			smp["input"] = times[smp["input"]]
			smp["output"] = keep(smp["output"], rows)
	img_views = {}
	for im in js.get("images", []):
		v = views[im["bufferView"]]
		raw = binary[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
		pic = Image.open(io.BytesIO(raw)).convert("RGB")
		lim = nsize if "nrm" in im.get("name", "") else size  # (bump pictures matter least on the page)
		for spec in [b for b in opts.get("big", "").split(",") if b]:  # e.g. big=chest_leather_baked_col:1024
			w, px = spec.split(":")
			if w in im.get("name", ""):
				lim = int(px)
		if any(w in im.get("name", "") for w in drop):
			lim = 8  # (a left-out part's pictures: a dot)
		if max(pic.size) > lim:
			pic = pic.resize((lim, lim) if pic.size[0] == pic.size[1] else (lim, int(lim * pic.size[1] / pic.size[0])), Image.LANCZOS)
		b = io.BytesIO()
		pic.save(b, "JPEG", quality=82)
		im["bufferView"] = len(chunks)
		im["mimeType"] = "image/jpeg"
		chunks.append(b.getvalue())
		strides.append(0)
	js["accessors"] = new_acc
	blob, new_views = b"", []
	for c in chunks:
		blob += b"\0" * ((4 - len(blob) % 4) % 4)
		new_views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(c)})
		blob += c
	js["bufferViews"] = new_views
	js["buffers"] = [{"byteLength": len(blob), "uri": "data:application/octet-stream;base64," + base64.b64encode(blob).decode()}]
	text = json.dumps(js, separators=(",", ":"))
	open(out, "w", encoding="utf-8").write(text)
	print(f"PAGE_COPY {out} {len(text) / 1e6:.1f} MB ({len(js.get('images', []))} pictures at most {size} px, every {every} frames)")


main()
