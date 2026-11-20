"""Clean the JPEG pictures inside a .glb so Godot can read them (Nov 20).

Blender's JPEG export writes extra info blocks (an EXIF block, comments, a colour profile) into each picture. Godot's
JPEG reader (libjpeg-turbo) refused those pictures ("Couldn't load image ... image/jpeg"), so the skeleton miners came
into the game plain white. This drops the extra blocks and keeps the picture itself byte for byte (nothing is
re-compressed, so nothing changes in how it looks).

Plain Python, no extra modules: it runs inside Blender (kaykit_miners.py calls clean()) and on its own:
    python tools/asset_forge/glb_jpeg_clean.py assets/models/creatures/foreman.glb [more.glb ...]
"""
import json
import struct
import sys

KEEP_BEFORE_SCAN = {0xC0, 0xC1, 0xC2, 0xC4, 0xDB, 0xDD, 0xE0}  # frame, huffman/quant tables, restart, JFIF header


def strip_jpeg(data: bytes) -> bytes:
	"""The same picture without the extra info blocks (EXIF, comments, colour profile)."""
	if data[:2] != b"\xff\xd8":
		return data
	out = bytearray(b"\xff\xd8")
	i = 2
	while i + 4 <= len(data):
		if data[i] != 0xFF:
			return data  # (not a layout we know: leave it alone)
		marker = data[i + 1]
		if marker == 0xFF:
			i += 1
			continue
		length = data[i + 2] * 256 + data[i + 3]
		if marker == 0xDA:  # the picture itself starts: copy it all
			out += data[i:]
			return bytes(out)
		if marker in KEEP_BEFORE_SCAN:
			out += data[i:i + 2 + length]
		i += 2 + length
	return data


def clean(path: str) -> int:
	"""Rewrites the .glb with clean pictures. Returns how many pictures changed."""
	raw = open(path, "rb").read()
	magic, version, _total = struct.unpack("<4sII", raw[:12])
	if magic != b"glTF":
		return 0
	jlen = struct.unpack("<I", raw[12:16])[0]
	doc = json.loads(raw[20:20 + jlen])
	b0 = 20 + jlen
	blen = struct.unpack("<I", raw[b0:b0 + 4])[0]
	blob = raw[b0 + 8:b0 + 8 + blen]
	views = doc.get("bufferViews", [])
	image_views = {im["bufferView"]: im for im in doc.get("images", []) if im.get("mimeType") == "image/jpeg" and "bufferView" in im}
	changed = 0
	new_blob = bytearray()
	for vi in sorted(range(len(views)), key=lambda k: views[k].get("byteOffset", 0)):
		v = views[vi]
		part = blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
		if vi in image_views:
			clean_part = strip_jpeg(part)
			if clean_part != part:
				changed += 1
				part = clean_part
		while len(new_blob) % 4:
			new_blob += b"\x00"
		v["byteOffset"] = len(new_blob)
		v["byteLength"] = len(part)
		new_blob += part
	if changed == 0:
		return 0
	while len(new_blob) % 4:
		new_blob += b"\x00"
	doc["buffers"][0]["byteLength"] = len(new_blob)
	js = json.dumps(doc, separators=(",", ":")).encode()
	while len(js) % 4:
		js += b" "
	total = 12 + 8 + len(js) + 8 + len(new_blob)
	with open(path, "wb") as f:
		f.write(struct.pack("<4sII", b"glTF", version, total))
		f.write(struct.pack("<I4s", len(js), b"JSON") + js)
		f.write(struct.pack("<I4s", len(new_blob), b"BIN\x00") + bytes(new_blob))
	return changed


if __name__ == "__main__":
	for p in sys.argv[1:]:
		print(p, clean(p), "pictures cleaned")
