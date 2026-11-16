"""Makes Blender's JPEG textures inside .glb models readable by Godot.

Blender 5.3 writes extra info blocks into every JPEG it saves. Godot 4.7.2's JPEG reader rejects those
pictures ("Couldn't load image ... image/jpeg"), so the model shows up WHITE in the game. Tested Nov 16: the
one that breaks it is the colour profile (APP2 "ICC_PROFILE"); the small EXIF block (APP1) is harmless. This
removes all the extra blocks (APP1..APP15; the picture itself is untouched) and rewrites the .glb.
EVERY script that exports a .glb with JPEG pictures must call it (the bake script didn't: that was F164).

    python tools/asset_forge/glb_jpeg_fix.py model.glb [more.glb ...]
or from code (also inside Blender): import glb_jpeg_fix; glb_jpeg_fix.fix(path)
Pure Python, no extra libraries. Found by Claude 3 on Nov 14, 2026.
"""
import json
import struct
import sys


def strip_jpeg(d: bytes) -> bytes:
	if d[:2] != b"\xff\xd8":
		return d
	out = bytearray(d[:2])
	i = 2
	while i + 4 <= len(d):
		if d[i] != 0xFF:
			return d  # not what we expected: leave the picture alone
		m = d[i + 1]
		if m == 0xDA:  # start of the picture data: copy the rest as it is
			out += d[i:]
			return bytes(out)
		seg_len = struct.unpack(">H", d[i + 2:i + 4])[0]
		if not 0xE1 <= m <= 0xEF:
			out += d[i:i + 2 + seg_len]
		i += 2 + seg_len
	return d


def fix(path: str) -> int:
	"""Returns how many pictures were fixed."""
	b = open(path, "rb").read()
	if b[:4] != b"glTF":
		return 0
	jlen = struct.unpack("<I", b[12:16])[0]
	j = json.loads(b[20:20 + jlen])
	bin_start = 20 + jlen + 8
	blen = struct.unpack("<I", b[20 + jlen:24 + jlen])[0]
	binc = b[bin_start:bin_start + blen]
	jpeg_views = {im["bufferView"] for im in j.get("images", []) if im.get("mimeType") == "image/jpeg" and "bufferView" in im}
	fixed = 0
	new_bin = bytearray()
	for k, bv in enumerate(j["bufferViews"]):
		data = binc[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
		if k in jpeg_views:
			s = strip_jpeg(data)
			fixed += s != data
			data = s
		while len(new_bin) % 4:
			new_bin += b"\x00"
		bv["byteOffset"] = len(new_bin)
		bv["byteLength"] = len(data)
		new_bin += data
	if not fixed:
		return 0
	while len(new_bin) % 4:
		new_bin += b"\x00"
	j["buffers"][0]["byteLength"] = len(new_bin)
	js = json.dumps(j, separators=(",", ":")).encode()
	js += b" " * ((4 - len(js) % 4) % 4)
	total = 12 + 8 + len(js) + 8 + len(new_bin)
	out = struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(new_bin), 0x004E4942) + new_bin
	open(path, "wb").write(out)
	return fixed


if __name__ == "__main__":
	for p in sys.argv[1:]:
		print(p, "fixed", fix(p), "pictures")
