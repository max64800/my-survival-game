"""Shrink a .glb for the 3D page and write it as glTF text with the buffer inside (the page host doesn't serve .glb).
- pictures: half size, JPEG quality 78
- mesh: drop TANGENT and second UV sets (the page doesn't need them)
- animation: drop channels that never change
usage: python -I tools/asset_forge/pack_page_gltf.py in.glb out.json (needs Pillow)
"""
import base64, io, json, struct, sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
b = open(src, "rb").read()
n = struct.unpack("<I", b[12:16])[0]
j = json.loads(b[20:20 + n])
off = 20 + n
binlen = struct.unpack("<I", b[off:off + 4])[0]
blob = b[off + 8: off + 8 + binlen]
bv, acc = j["bufferViews"], j["accessors"]


def view_bytes(i):
    v = bv[i]
    o = v.get("byteOffset", 0)
    return blob[o:o + v["byteLength"]]


new_data = {}  # bufferView index -> replacement bytes
for im in j.get("images", []):
    raw = view_bytes(im["bufferView"])
    pic = Image.open(io.BytesIO(raw)).convert("RGB")
    pic = pic.resize((max(1, pic.width // 2), max(1, pic.height // 2)), Image.LANCZOS)
    out = io.BytesIO()
    pic.save(out, "JPEG", quality=78)
    new_data[im["bufferView"]] = out.getvalue()
    im["mimeType"] = "image/jpeg"

done_w = set()
for m in j["meshes"]:
    for p in m["primitives"]:
        for k in ["TANGENT", "TEXCOORD_1", "TEXCOORD_2"]:
            p["attributes"].pop(k, None)
        w = p["attributes"].get("WEIGHTS_0")
        x = acc[w] if w is not None else None
        if x and x["componentType"] == 5126 and w not in done_w and bv[x["bufferView"]].get("byteStride", 16) == 16:
            done_w.add(w)  # skin weights as one byte each (0..255), each vertex's four still adding up to 255
            raw = view_bytes(x["bufferView"])[x.get("byteOffset", 0):]
            f = struct.unpack("<%df" % (x["count"] * 4), raw[:x["count"] * 16])
            q = bytearray()
            for i in range(0, len(f), 4):
                v = [max(0, round(f[i + c] * 255)) for c in range(4)]
                v[v.index(max(v))] += 255 - sum(v)
                q += bytes(v)
            new_data[x["bufferView"]] = bytes(q)
            x.update(componentType=5121, normalized=True)
            x.pop("byteOffset", None)
            x.pop("min", None)
            x.pop("max", None)
            bv[x["bufferView"]].pop("byteStride", None)

## A channel that never changes still matters (Nov 19 mistake: dropping them lost the dwarf shaping, the shortened legs
## and thick arms are steady values, so the page showed a tall thin human): keep it as ONE key instead of one per frame.
def add_view(data):
    bv.append({"buffer": 0, "byteLength": len(data)})
    new_data[len(bv) - 1] = data
    return len(bv) - 1


one_time = None
for a in j.get("animations", []):
    for si, s in enumerate(a["samplers"]):
        x = acc[s["output"]]
        data = view_bytes(x["bufferView"])[x.get("byteOffset", 0):]
        comps = {"VEC3": 3, "VEC4": 4, "SCALAR": 1}[x["type"]]
        vals = struct.unpack("<%df" % (x["count"] * comps), data[:x["count"] * comps * 4])
        first = vals[:comps]
        if x["count"] > 1 and all(abs(vals[i] - first[i % comps]) < 1e-5 for i in range(len(vals))):
            if one_time is None:
                acc.append({"bufferView": add_view(struct.pack("<f", 0.0)), "componentType": 5126, "count": 1,
                            "type": "SCALAR", "min": [0.0], "max": [0.0]})
                one_time = len(acc) - 1
            acc.append({"bufferView": add_view(struct.pack("<%df" % comps, *first)), "componentType": 5126,
                        "count": 1, "type": x["type"]})
            a["samplers"][si] = {"input": one_time, "output": len(acc) - 1, "interpolation": "STEP"}

# Which accessors/views are still used? Rebuild the buffer with only those.
used_acc = set()
for m in j["meshes"]:
    for p in m["primitives"]:
        used_acc.update(p["attributes"].values())
        if "indices" in p:
            used_acc.add(p["indices"])
        for t in p.get("targets", []):
            used_acc.update(t.values())
for s in j.get("skins", []):
    if "inverseBindMatrices" in s:
        used_acc.add(s["inverseBindMatrices"])
for a in j.get("animations", []):
    for ch in a["channels"]:
        s = a["samplers"][ch["sampler"]]
        used_acc.update([s["input"], s["output"]])
used_views = {acc[i]["bufferView"] for i in used_acc if "bufferView" in acc[i]}
used_views.update(im["bufferView"] for im in j.get("images", []))

out = bytearray()
view_map = {}
new_views = []
for i, v in enumerate(bv):
    if i not in used_views:
        continue
    data = new_data.get(i, view_bytes(i))
    while len(out) % 4:
        out.append(0)
    nv = {k: val for k, val in v.items() if k not in ("byteOffset", "byteLength")}
    nv.update(buffer=0, byteOffset=len(out), byteLength=len(data))
    view_map[i] = len(new_views)
    new_views.append(nv)
    out += data
for x in acc:
    if "bufferView" in x:
        x["bufferView"] = view_map.get(x["bufferView"], 0)
for im in j.get("images", []):
    im["bufferView"] = view_map[im["bufferView"]]
# Re-point animation samplers: keep only used samplers.
for a in j.get("animations", []):
    smap, ns = {}, []
    for ch in a["channels"]:
        if ch["sampler"] not in smap:
            smap[ch["sampler"]] = len(ns)
            ns.append(a["samplers"][ch["sampler"]])
        ch["sampler"] = smap[ch["sampler"]]
    a["samplers"] = ns
j["bufferViews"] = new_views
j["buffers"] = [{"byteLength": len(out), "uri": "data:application/octet-stream;base64," + base64.b64encode(bytes(out)).decode()}]
open(dst, "w").write(json.dumps(j, separators=(",", ":")))
print(dst, "bin %.1f MB, file %.1f MB" % (len(out) / 1e6, len(json.dumps(j)) / 1e6))
