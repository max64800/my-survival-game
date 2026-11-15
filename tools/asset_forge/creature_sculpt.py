"""Sculpt-and-bake add-on for hand-built creatures (by Claude 3), the way game studios make creatures, all by script:

1. melt()      a part made of glued pieces becomes ONE smooth skin (voxel remesh + a little smoothing): no seams.
2. carve_*()   sculpted detail on the dense skin: stone cracks, chips and grain; chitin creases and dents.
3. game_copy() a light copy for the game (fewer triangles) with its own UV map (how a picture wraps it).
4. bake()      the dense sculpt's detail is copied onto the light copy as pictures: a normal map (the light catches the
               cracks) and a hand-painted colour map (base colour, dark cavities, light worn edges, light tops, moss in
               the cracks, brush-stroke variation), painted by a shader and baked with Cycles.

Nothing here is picture-to-3D (MODEL-RULES Rule 1): every shape comes from our own build script.
"""
import math
import random

import bmesh
import bpy
from mathutils import Vector, noise


def _select_only(o):
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o


def _apply_all(o):
	_select_only(o)
	for m in list(o.modifiers):
		bpy.ops.object.modifier_apply(modifier=m.name)


def melt(objs, voxel=0.005, smooth=4, name="skin"):
	"""Join objects and remesh them into one closed skin; smoothing rounds the joins into soft fillets."""
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	_apply_all(o)
	m = o.modifiers.new("remesh", "REMESH")
	m.mode = "VOXEL"
	m.voxel_size = voxel
	m.adaptivity = 0.0
	if smooth:
		s = o.modifiers.new("smooth", "SMOOTH")
		s.iterations = smooth
		s.factor = 0.5
	_apply_all(o)
	o.name = name
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def _displace(o, fn):
	"""Move every vertex along its normal by fn(position, normal) metres."""
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bm.normal_update()
	moves = [(v, fn(v.co.copy(), v.normal.copy())) for v in bm.verts]
	for v, h in moves:
		v.co += v.normal * h
	bm.to_mesh(o.data)
	bm.free()


def _crack(p, scale):
	"""0 away from a crack line, 1 on it (Voronoi cell borders)."""
	d = noise.voronoi(p * scale, distance_metric="DISTANCE")[0]
	return max(0.0, 1.0 - (d[1] - d[0]) / 0.09) ** 2


def carve_stone(o, seed=1, grain=0.0022, crack=0.004, chips=0.008, soften=2):
	"""Stone: rough grain, a few hairline cracks, and chipped corners (high curvature parts knocked off)."""
	off = Vector((seed * 13.1, seed * 7.7, seed * 3.3))

	def fn(p, n):
		q = p + off
		h = grain * noise.fractal(q * 22, 0.6, 2.2, 4)
		h -= crack * _crack(q, 4.5) * (1.0 if noise.noise(q * 3 + Vector((9, 9, 9))) > 0.1 else 0.0)  # a few cracks, not a web
		ch = noise.noise(q * 6)
		if ch > 0.35:  # big chips: flat bites out of the stone
			h -= chips * (ch - 0.35) / 0.65
		return h
	_displace(o, fn)
	s = o.modifiers.new("soften", "SMOOTH")
	s.iterations = soften
	s.factor = 0.5
	_apply_all(o)


def carve_chitin(o, seed=2, dents=0.003, grain=0.0012):
	"""Chitin (beetle shell skin): broad shallow dents and a fine grain."""
	off = Vector((seed * 5.3, seed * 2.1, seed * 9.9))

	def fn(p, n):
		q = p + off
		return dents * noise.noise(q * 9) + grain * noise.fractal(q * 60, 0.5, 2.0, 3)
	_displace(o, fn)


def detail_copy(o, levels=2, name=None):
	"""A dense copy (simple subdivision, shape unchanged) to carve small detail into; the original stays the game copy."""
	_select_only(o)
	bpy.ops.object.duplicate()
	h = bpy.context.view_layer.objects.active
	h.name = name or (o.name + "_high")
	_apply_all(h)
	m = h.modifiers.new("dense", "SUBSURF")
	m.subdivision_type = "SIMPLE"
	m.levels = levels
	m.render_levels = levels
	_apply_all(h)
	return h


def uv_only(o):
	"""Give a mesh a UV map without changing its shape (apply its modifiers first)."""
	_apply_all(o)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=0.006)
	bpy.ops.object.mode_set(mode="OBJECT")
	return o


def game_copy(high, tris, name):
	"""A light copy for the game, about `tris` triangles, with a UV map."""
	_select_only(high)
	bpy.ops.object.duplicate()
	low = bpy.context.view_layer.objects.active
	low.name = name
	now = sum(len(p.vertices) - 2 for p in low.data.polygons)
	d = low.modifiers.new("decimate", "DECIMATE")
	d.ratio = min(1.0, tris / max(1, now))
	_apply_all(low)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004)
	bpy.ops.object.mode_set(mode="OBJECT")
	for p in low.data.polygons:
		p.use_smooth = True
	return low


# ---------------------------------------------------------------- painting (a shader on the dense sculpt, baked)

def _node(nt, kind, **inputs):
	n = nt.nodes.new(kind)
	for k, v in inputs.items():
		if k in n.inputs:
			n.inputs[k].default_value = v
		else:
			setattr(n, k, v)
	return n


def lin(c):
	"""Colour picked by eye (sRGB 0..1, like a paint program) -> the linear value Blender's shaders use."""
	return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)


def paint_material(name, base, dark, light, moss=None, moss_amount=0.0, strokes=0.12, top_light=0.18, edge=0.35, seed=0.0,
		key=0.35, key_dir=(0.35, -0.45, 0.82)):
	"""A 'hand-painted' look as a shader: base colour with brush-stroke variation, darker in cavities (ambient
	occlusion), lighter on worn edges (pointiness) and on tops (facing up), moss in the up-facing cavities.
	Colours are (r, g, b) 0..1 as picked by eye (sRGB). Meant to be BAKED (Cycles) into a colour picture."""
	base, dark, light = lin(base), lin(dark), lin(light)
	moss = lin(moss) if moss else None
	top_light *= 0.5  # (linear values are smaller)
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	outn = _node(nt, "ShaderNodeOutputMaterial")
	emit = _node(nt, "ShaderNodeEmission")
	nt.links.new(emit.outputs[0], outn.inputs["Surface"])
	geo = _node(nt, "ShaderNodeNewGeometry")
	coord = _node(nt, "ShaderNodeTexCoord")
	# brush strokes: noise stretched along one direction
	mapn = _node(nt, "ShaderNodeMapping")
	mapn.inputs["Scale"].default_value = (9.0, 2.5, 9.0)
	mapn.inputs["Location"].default_value = (seed, seed * 0.7, 0)
	nt.links.new(coord.outputs["Object"], mapn.inputs["Vector"])
	nz = _node(nt, "ShaderNodeTexNoise", **{"Scale": 3.0, "Detail": 3.0, "Roughness": 0.55})
	nt.links.new(mapn.outputs[0], nz.inputs["Vector"])
	col = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
	col.inputs[6].default_value = (*dark, 1)
	col.inputs[7].default_value = (*light, 1)
	stroke = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.3, "From Max": 0.7, "To Min": 0.5 - strokes, "To Max": 0.5 + strokes})
	nt.links.new(nz.outputs["Fac"], stroke.inputs["Value"])
	# base = mix(dark, light, 0.5 +- strokes) but centred on `base`
	basemix = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
	basemix.inputs[6].default_value = (*base, 1)
	nt.links.new(stroke.outputs[0], col.inputs[0])
	basemix.inputs[0].default_value = 0.5
	nt.links.new(col.outputs[2], basemix.inputs[7])
	# tops lighter (painted sunlight from above)
	sep = _node(nt, "ShaderNodeSeparateXYZ")
	nt.links.new(geo.outputs["Normal"], sep.inputs[0])
	up = _node(nt, "ShaderNodeMapRange", **{"From Min": -0.3, "From Max": 1.0, "To Min": -top_light, "To Max": top_light})
	nt.links.new(sep.outputs["Z"], up.inputs["Value"])
	toplit = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="ADD")
	nt.links.new(basemix.outputs[2], toplit.inputs[6])
	comb = _node(nt, "ShaderNodeCombineXYZ")
	for k in ("X", "Y", "Z"):
		nt.links.new(up.outputs[0], comb.inputs[k])
	nt.links.new(comb.outputs[0], toplit.inputs[7])
	toplit.inputs[0].default_value = 1.0
	# worn edges lighter (pointiness: convex = bright)
	pt = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.52, "From Max": 0.6, "To Min": 0.0, "To Max": edge})
	nt.links.new(geo.outputs["Pointiness"], pt.inputs["Value"])
	edged = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="SCREEN")
	nt.links.new(pt.outputs[0], edged.inputs[0])
	nt.links.new(toplit.outputs[2], edged.inputs[6])
	edged.inputs[7].default_value = (*light, 1)
	# cavities darker (ambient occlusion)
	ao = _node(nt, "ShaderNodeAmbientOcclusion", **{"Distance": 0.06})
	ao.samples = 16
	aor = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.2, "From Max": 0.95, "To Min": 0.0, "To Max": 1.0})
	nt.links.new(ao.outputs["AO"], aor.inputs["Value"])
	shade = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
	nt.links.new(aor.outputs[0], shade.inputs[0])
	shade.inputs[6].default_value = (*[c * 0.35 for c in dark], 1)
	nt.links.new(edged.outputs[2], shade.inputs[7])
	last = shade
	if moss and moss_amount > 0:
		# moss: in the cavities, facing up-ish, broken up by noise
		cav = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.75, "From Max": 0.35, "To Min": 0.0, "To Max": 1.0})
		nt.links.new(ao.outputs["AO"], cav.inputs["Value"])
		upm = _node(nt, "ShaderNodeMapRange", **{"From Min": -0.2, "From Max": 0.4, "To Min": 0.0, "To Max": 1.0})
		nt.links.new(sep.outputs["Z"], upm.inputs["Value"])
		mn = _node(nt, "ShaderNodeTexNoise", **{"Scale": 14.0, "Detail": 4.0})
		mnr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.42, "From Max": 0.6, "To Min": 0.0, "To Max": 1.0})
		nt.links.new(mn.outputs["Fac"], mnr.inputs["Value"])
		mul1 = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
		nt.links.new(cav.outputs[0], mul1.inputs[0])
		nt.links.new(upm.outputs[0], mul1.inputs[1])
		mul2 = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
		nt.links.new(mul1.outputs[0], mul2.inputs[0])
		nt.links.new(mnr.outputs[0], mul2.inputs[1])
		mul3 = _node(nt, "ShaderNodeMath", operation="MULTIPLY", use_clamp=True)
		nt.links.new(mul2.outputs[0], mul3.inputs[0])
		mul3.inputs[1].default_value = moss_amount * 2.5
		mossmix = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(mul3.outputs[0], mossmix.inputs[0])
		nt.links.new(shade.outputs[2], mossmix.inputs[6])
		mossmix.inputs[7].default_value = (*moss, 1)
		last = mossmix
	if key:
		# painted light from the upper front: faces turned to it lighter, faces turned away darker (the painting's light)
		dp = _node(nt, "ShaderNodeVectorMath", operation="DOT_PRODUCT")
		nt.links.new(geo.outputs["Normal"], dp.inputs[0])
		dp.inputs[1].default_value = Vector(key_dir).normalized()
		kr = _node(nt, "ShaderNodeMapRange", **{"From Min": -0.4, "From Max": 1.0, "To Min": 1 - key, "To Max": 1 + key * 0.6})
		nt.links.new(dp.outputs["Value"], kr.inputs["Value"])
		kc = _node(nt, "ShaderNodeCombineXYZ")
		for k in ("X", "Y", "Z"):
			nt.links.new(kr.outputs[0], kc.inputs[k])
		lit = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
		lit.inputs[0].default_value = 1.0
		nt.links.new(last.outputs[2], lit.inputs[6])
		nt.links.new(kc.outputs[0], lit.inputs[7])
		last = lit
	nt.links.new(last.outputs[2], emit.inputs["Color"])
	return m


def glow_paint(name, core, rim, lines=0.35, cells=7.0):
	"""A glowing gem/amber look: bright core facing you, deeper colour at the rim, honeycomb facet lines."""
	core, rim = lin(core), lin(rim)
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	outn = _node(nt, "ShaderNodeOutputMaterial")
	emit = _node(nt, "ShaderNodeEmission")
	nt.links.new(emit.outputs[0], outn.inputs["Surface"])
	coord = _node(nt, "ShaderNodeTexCoord")
	geo = _node(nt, "ShaderNodeNewGeometry")
	# "core": how much the surface faces outward from the dome's middle (bright middle, deep rim)
	vor = _node(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE", **{"Scale": cells})
	nt.links.new(coord.outputs["Object"], vor.inputs["Vector"])
	ln = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.0, "From Max": 0.06, "To Min": 1.0 - lines, "To Max": 1.0})
	nt.links.new(vor.outputs["Distance"], ln.inputs["Value"])
	vor2 = _node(nt, "ShaderNodeTexVoronoi", **{"Scale": cells})
	nt.links.new(coord.outputs["Object"], vor2.inputs["Vector"])
	cell = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.0, "From Max": 1.0, "To Min": 0.85, "To Max": 1.15})
	nt.links.new(vor2.outputs["Color"], cell.inputs["Value"])
	sep = _node(nt, "ShaderNodeSeparateXYZ")
	nt.links.new(geo.outputs["Normal"], sep.inputs[0])
	mix = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
	mix.inputs[6].default_value = (*rim, 1)
	mix.inputs[7].default_value = (*core, 1)
	upr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.0, "From Max": 0.9, "To Min": 0.0, "To Max": 1.0})
	nt.links.new(sep.outputs["Z"], upr.inputs["Value"])
	nt.links.new(upr.outputs[0], mix.inputs[0])
	mul = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
	nt.links.new(ln.outputs[0], mul.inputs[0])
	nt.links.new(cell.outputs[0], mul.inputs[1])
	cc = _node(nt, "ShaderNodeCombineXYZ")
	for k in ("X", "Y", "Z"):
		nt.links.new(mul.outputs[0], cc.inputs[k])
	fin = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
	fin.inputs[0].default_value = 1.0
	nt.links.new(mix.outputs[2], fin.inputs[6])
	nt.links.new(cc.outputs[0], fin.inputs[7])
	nt.links.new(fin.outputs[2], emit.inputs["Color"])
	return m


def carve_moss(o, seed=4, height=0.03, cover=0.15):
	"""Moss growing in the cracks: soft lumpy cushions where noise says so, bare dark ground elsewhere."""
	off = Vector((seed * 3.7, seed * 1.9, seed * 8.1))

	def fn(p, n):
		q = p + off
		f = noise.fractal(q * 11, 0.55, 2.0, 4) + cover
		return height * max(0.0, f) ** 0.7 + 0.004 * noise.noise(q * 70)
	_displace(o, fn)
	s = o.modifiers.new("soften", "SMOOTH")
	s.iterations = 2
	s.factor = 0.5
	_apply_all(o)


def bake(high, low, tex_size=1024, name="baked", normal=True, emissive=0.0):
	"""Bake the dense sculpt (with its paint material) onto the light copy: colour + normal map. Returns the low
	copy's new game material (painted colour, normal map)."""
	scene = bpy.context.scene
	scene.render.engine = "CYCLES"
	scene.cycles.samples = 24
	scene.cycles.device = "CPU"
	col = bpy.data.images.new(f"{name}_col", tex_size, tex_size)
	nrm = bpy.data.images.new(f"{name}_nrm", tex_size, tex_size, is_data=True) if normal else None
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = 0.95
	b.inputs["Specular IOR Level"].default_value = 0.15  # painted look: little plastic shine
	tcol = nt.nodes.new("ShaderNodeTexImage")
	tcol.image = col
	nt.links.new(tcol.outputs["Color"], b.inputs["Base Color"])
	tn = None
	if normal:
		tn = nt.nodes.new("ShaderNodeTexImage")
		tn.image = nrm
		tn.image.colorspace_settings.name = "Non-Color"
		nm = nt.nodes.new("ShaderNodeNormalMap")
		nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
		nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
	if emissive:  # glowing parts: the painted colour also lights itself
		nt.links.new(tcol.outputs["Color"], b.inputs["Emission Color"])
		b.inputs["Emission Strength"].default_value = emissive
	low.data.materials.clear()
	low.data.materials.append(m)
	bpy.ops.object.select_all(action="DESELECT")
	high.select_set(True)
	low.select_set(True)
	bpy.context.view_layer.objects.active = low
	ext = 0.03
	nt.nodes.active = tcol
	bpy.ops.object.bake(type="EMIT", use_selected_to_active=True, cage_extrusion=ext, max_ray_distance=ext * 2, margin=8)
	if normal:
		nt.nodes.active = tn
		bpy.ops.object.bake(type="NORMAL", use_selected_to_active=True, cage_extrusion=ext, max_ray_distance=ext * 2, margin=8)
	for img in (col, nrm):
		if img:
			img.pack()
	return m
