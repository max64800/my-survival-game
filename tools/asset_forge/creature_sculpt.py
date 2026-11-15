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
from mathutils import Vector, kdtree, noise


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


def game_copy(high, tris, name, remesh=None):
	"""A light copy for the game, about `tris` triangles, with a UV map. remesh (metres): build it as an even
	voxel remesh instead of thinning the sculpt (thinning can fold triangles over on thin parts like eyelids, and a
	folded triangle bakes the inside of the part: dark shards)."""
	_select_only(high)
	bpy.ops.object.duplicate()
	low = bpy.context.view_layer.objects.active
	low.name = name
	if remesh:
		m = low.modifiers.new("remesh", "REMESH")
		m.mode = "VOXEL"
		m.voxel_size = remesh
		_apply_all(low)
	else:
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
		key=0.35, key_dir=(0.35, -0.45, 0.82), tint_attr=None, scratches=0.0, grime=0.0, root=None, root_attr="grad", ao_samples=16, ao_local=False):
	"""A 'hand-painted' look as a shader: base colour with brush-stroke variation, darker in cavities (ambient
	occlusion), lighter on worn edges (pointiness) and on tops (facing up), moss in the up-facing cavities.
	Colours are (r, g, b) 0..1 as picked by eye (sRGB). Meant to be BAKED (Cycles) into a colour picture.
	Wear and tear (round 5): tint_attr = a colour attribute giving each stone its own shade (tint_islands);
	scratches = thin pale scratch lines (also cut into the baked normal map); grime = darker stains;
	root = a colour the part darkens to at its root (a 0..1 attribute, 0 = root; gradient_attr)."""
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
	if tint_attr:  # each stone its own shade (warmer, cooler, darker, lighter)
		ta = _node(nt, "ShaderNodeAttribute", attribute_name=tint_attr)
		tm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
		tm.inputs[0].default_value = 1.0
		nt.links.new(basemix.outputs[2], tm.inputs[6])
		nt.links.new(ta.outputs["Color"], tm.inputs[7])
		basemix = tm
	if root:  # darker toward the root (claws, fangs)
		ra = _node(nt, "ShaderNodeAttribute", attribute_name=root_attr)
		rr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.0, "From Max": 0.6, "To Min": 0.0, "To Max": 1.0})
		nt.links.new(ra.outputs["Fac"], rr.inputs["Value"])
		rm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(rr.outputs[0], rm.inputs[0])
		rm.inputs[6].default_value = (*lin(root), 1)
		nt.links.new(basemix.outputs[2], rm.inputs[7])
		basemix = rm
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
	ao.samples = ao_samples
	ao.only_local = ao_local  # True: only the part itself makes shadows (other parts pushed into it would paint dark patches)
	aor = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.2, "From Max": 0.95, "To Min": 0.0, "To Max": 1.0})
	nt.links.new(ao.outputs["AO"], aor.inputs["Value"])
	shade = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
	nt.links.new(aor.outputs[0], shade.inputs[0])
	shade.inputs[6].default_value = (*[c * 0.35 for c in dark], 1)
	nt.links.new(edged.outputs[2], shade.inputs[7])
	last = shade
	if grime:  # darker stains, like old dirt
		gn = _node(nt, "ShaderNodeTexNoise", **{"Scale": 2.2, "Detail": 5.0, "Roughness": 0.6})
		gl = _node(nt, "ShaderNodeMapping")
		gl.inputs["Location"].default_value = (seed * 3.1 + 7, seed, 2)
		nt.links.new(coord.outputs["Object"], gl.inputs["Vector"])
		nt.links.new(gl.outputs[0], gn.inputs["Vector"])
		gr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.45, "From Max": 0.68, "To Min": 0.0, "To Max": grime})
		nt.links.new(gn.outputs["Fac"], gr.inputs["Value"])
		gm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(gr.outputs[0], gm.inputs[0])
		nt.links.new(last.outputs[2], gm.inputs[6])
		gm.inputs[7].default_value = (*[c * 0.45 for c in dark], 1)
		last = gm
	if scratches:  # thin scratches: pale fresh stone in the line, and cut in (bump -> baked into the normal map)
		mask = None
		for k, (sc, stretch) in enumerate(((5.0, (1.0, 1.0, 1.0)), (8.0, (1.6, 0.6, 1.0)), (12.0, (0.7, 1.4, 1.2)))):
			mp = _node(nt, "ShaderNodeMapping")
			mp.inputs["Scale"].default_value = stretch
			mp.inputs["Location"].default_value = (seed + k * 11.3, k * 5.1, k * 2.7)
			nt.links.new(coord.outputs["Object"], mp.inputs["Vector"])
			ln = _node(nt, "ShaderNodeTexNoise", **{"Scale": sc, "Detail": 0.0})
			nt.links.new(mp.outputs[0], ln.inputs["Vector"])
			ab = _node(nt, "ShaderNodeMath", operation="SUBTRACT")
			nt.links.new(ln.outputs["Fac"], ab.inputs[0])
			ab.inputs[1].default_value = 0.5
			ab2 = _node(nt, "ShaderNodeMath", operation="ABSOLUTE")
			nt.links.new(ab.outputs[0], ab2.inputs[0])
			line = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.0, "From Max": 0.006 + 0.002 * k, "To Min": 1.0, "To Max": 0.0})
			nt.links.new(ab2.outputs[0], line.inputs["Value"])
			mk = _node(nt, "ShaderNodeTexNoise", **{"Scale": sc * 1.7, "Detail": 1.0})
			nt.links.new(mp.outputs[0], mk.inputs["Vector"])
			mkr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.56, "From Max": 0.64, "To Min": 0.0, "To Max": 1.0})
			nt.links.new(mk.outputs["Fac"], mkr.inputs["Value"])
			one = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
			nt.links.new(line.outputs[0], one.inputs[0])
			nt.links.new(mkr.outputs[0], one.inputs[1])
			if mask is None:
				mask = one
			else:
				mx = _node(nt, "ShaderNodeMath", operation="MAXIMUM")
				nt.links.new(mask.outputs[0], mx.inputs[0])
				nt.links.new(one.outputs[0], mx.inputs[1])
				mask = mx
		sf = _node(nt, "ShaderNodeMath", operation="MULTIPLY", use_clamp=True)
		nt.links.new(mask.outputs[0], sf.inputs[0])
		sf.inputs[1].default_value = scratches
		sm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(sf.outputs[0], sm.inputs[0])
		nt.links.new(last.outputs[2], sm.inputs[6])
		sm.inputs[7].default_value = (*[min(1.0, c * 1.15) for c in light], 1)
		last = sm
		disp = _node(nt, "ShaderNodeDisplacement", **{"Midlevel": 0.0, "Scale": -0.0015})
		nt.links.new(mask.outputs[0], disp.inputs["Height"])
		nt.links.new(disp.outputs[0], outn.inputs["Displacement"])
		for holder in (m, getattr(m, "cycles", None)):  # bump only (the shape stays), so the bake's normal map gets the cuts
			if holder is not None and hasattr(holder, "displacement_method"):
				holder.displacement_method = "BUMP"
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


def glow_paint(name, core, rim, lines=0.35, cells=7.0, facets=0.0, cloud=0.0, bubbles=0.0, creases=0.0, key_dir=(0.35, -0.45, 0.82)):
	"""A glowing gem/amber look: bright core facing you, deeper colour at the rim, fracture lines inside.
	Round 5: facets = each flat facet catches the light differently; cloud = cloudy darker depths; bubbles = small
	bright specks trapped inside; creases = the facet edges light up."""
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
	last = fin

	def mult(fac_socket):
		c3 = _node(nt, "ShaderNodeCombineXYZ")
		for k in ("X", "Y", "Z"):
			nt.links.new(fac_socket, c3.inputs[k])
		mm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
		mm.inputs[0].default_value = 1.0
		nt.links.new(last.outputs[2], mm.inputs[6])
		nt.links.new(c3.outputs[0], mm.inputs[7])
		return mm
	if facets:
		dp = _node(nt, "ShaderNodeVectorMath", operation="DOT_PRODUCT")
		nt.links.new(geo.outputs["Normal"], dp.inputs[0])
		dp.inputs[1].default_value = Vector(key_dir).normalized()
		fr = _node(nt, "ShaderNodeMapRange", **{"From Min": -0.2, "From Max": 1.0, "To Min": 1 - facets, "To Max": 1 + facets})
		nt.links.new(dp.outputs["Value"], fr.inputs["Value"])
		last = mult(fr.outputs[0])
	if cloud:
		cn = _node(nt, "ShaderNodeTexNoise", **{"Scale": 3.5, "Detail": 6.0, "Roughness": 0.65})
		nt.links.new(coord.outputs["Object"], cn.inputs["Vector"])
		cr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.38, "From Max": 0.66, "To Min": 1 - cloud, "To Max": 1.0 + cloud * 0.3})
		nt.links.new(cn.outputs["Fac"], cr.inputs["Value"])
		last = mult(cr.outputs[0])
	if bubbles:
		bv = _node(nt, "ShaderNodeTexVoronoi", **{"Scale": 16.0})
		nt.links.new(coord.outputs["Object"], bv.inputs["Vector"])
		br = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.04, "From Max": 0.1, "To Min": 1.0, "To Max": 0.0})
		nt.links.new(bv.outputs["Distance"], br.inputs["Value"])
		bs = _node(nt, "ShaderNodeSeparateColor")
		nt.links.new(bv.outputs["Color"], bs.inputs[0])
		bk = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.7, "From Max": 0.72, "To Min": 0.0, "To Max": bubbles})
		nt.links.new(bs.outputs[0], bk.inputs["Value"])
		bm2 = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
		nt.links.new(br.outputs[0], bm2.inputs[0])
		nt.links.new(bk.outputs[0], bm2.inputs[1])
		bmix = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(bm2.outputs[0], bmix.inputs[0])
		nt.links.new(last.outputs[2], bmix.inputs[6])
		bmix.inputs[7].default_value = (1.0, 0.92, 0.6, 1)
		last = bmix
	if creases:
		pr = _node(nt, "ShaderNodeMapRange", **{"From Min": 0.505, "From Max": 0.54, "To Min": 0.0, "To Max": creases})
		nt.links.new(geo.outputs["Pointiness"], pr.inputs["Value"])
		cm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="SCREEN")
		nt.links.new(pr.outputs[0], cm.inputs[0])
		nt.links.new(last.outputs[2], cm.inputs[6])
		cm.inputs[7].default_value = (1.0, 0.85, 0.5, 1)
		last = cm
	nt.links.new(last.outputs[2], emit.inputs["Color"])
	return m


def paint_eye(name, white=(0.95, 0.9, 0.8), white_shade=(0.62, 0.52, 0.45), iris_out=(0.3, 0.16, 0.07), iris_in=(0.62, 0.38, 0.16),
		ring=(0.12, 0.06, 0.03), pupil=(0.03, 0.02, 0.02), iris_deg=33.0, pupil_deg=15.0, shine_deg=6.5):
	"""A cartoon eye painted on one ball (no stacked discs): cream white (shaded toward the sides), a brown iris
	(dark outer ring, lighter toward the middle, fine streaks), a black pupil and a white shine. Reads the 'eye_t'
	(how straight the point looks out) and 'eye_h' (closeness to the shine spot) attributes from eye_attrs()."""
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	outn = _node(nt, "ShaderNodeOutputMaterial")
	emit = _node(nt, "ShaderNodeEmission")
	nt.links.new(emit.outputs[0], outn.inputs["Surface"])
	t = _node(nt, "ShaderNodeAttribute", attribute_name="eye_t").outputs["Fac"]
	h = _node(nt, "ShaderNodeAttribute", attribute_name="eye_h").outputs["Fac"]
	ci, cp, cs = math.cos(math.radians(iris_deg)), math.cos(math.radians(pupil_deg)), math.cos(math.radians(shine_deg))

	def rng(src, a, b, lo=0.0, hi=1.0):
		r = _node(nt, "ShaderNodeMapRange", **{"From Min": a, "From Max": b, "To Min": lo, "To Max": hi})
		nt.links.new(src, r.inputs["Value"])
		return r.outputs[0]

	def mix(fac, a, b):
		mm = _node(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
		nt.links.new(fac, mm.inputs[0])
		for sock, v in ((mm.inputs[6], a), (mm.inputs[7], b)):
			if isinstance(v, tuple):
				sock.default_value = (*lin(v), 1)
			else:
				nt.links.new(v, sock)
		return mm.outputs[2]
	col = mix(rng(t, -0.3, 0.7), white_shade, white)
	# iris streaks: fine noise around the pupil
	coord = _node(nt, "ShaderNodeTexCoord")
	sn = _node(nt, "ShaderNodeTexNoise", **{"Scale": 60.0, "Detail": 2.0})
	nt.links.new(coord.outputs["Object"], sn.inputs["Vector"])
	iris = mix(rng(t, ci, cp), iris_out, iris_in)
	iris = mix(rng(sn.outputs["Fac"], 0.35, 0.65, 0.0, 0.35), iris, (0.2, 0.1, 0.04))
	col = mix(rng(t, ci - 0.004, ci + 0.004), col, iris)
	ringf = _node(nt, "ShaderNodeMath", operation="MULTIPLY")
	nt.links.new(rng(t, ci - 0.004, ci + 0.004), ringf.inputs[0])
	nt.links.new(rng(t, ci + 0.006, ci + 0.03, 0.9, 0.0), ringf.inputs[1])
	col = mix(ringf.outputs[0], col, ring)
	col = mix(rng(t, cp - 0.003, cp + 0.003), col, pupil)
	col = mix(rng(h, cs - 0.0015, cs + 0.0015), col, (1.0, 1.0, 1.0))
	nt.links.new(col, emit.inputs["Color"])
	return m


# ---------------------------------------------------------------- attributes the paint reads

def islands(o):
	"""The separate pieces of a mesh: a list of vertex-index lists (connected by edges)."""
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bm.verts.ensure_lookup_table()
	seen, out = set(), []
	for v in bm.verts:
		if v.index in seen:
			continue
		stack, isl = [v], []
		seen.add(v.index)
		while stack:
			x = stack.pop()
			isl.append(x.index)
			for e in x.link_edges:
				y = e.other_vert(x)
				if y.index not in seen:
					seen.add(y.index)
					stack.append(y)
		out.append(isl)
	bm.free()
	return out


def island_kd(o):
	"""Remember which piece every vertex of `o` belongs to (call BEFORE melting it): (kd tree, piece of each point)."""
	isl = islands(o)
	owner = {}
	for k, idx in enumerate(isl):
		for i in idx:
			owner[i] = k
	mw = o.matrix_world
	kd = kdtree.KDTree(len(o.data.vertices))
	for v in o.data.vertices:
		kd.insert(mw @ v.co, v.index)
	kd.balance()
	return kd, owner


def tint_islands(high, kd_owner, seed=1, spread=0.13, name="tint"):
	"""Each original piece (stone) gets its own shade on the melted sculpt: a little warmer, cooler, lighter or
	darker, like real stones that came from different places (owner, round 5: not all the same colour)."""
	kd, owner = kd_owner
	shades = {}
	for k in set(owner.values()):
		r = random.Random(seed * 1000 + k)
		v = 1.0 + r.uniform(-spread, spread * 0.6)
		warm = r.choice((-1, 0, 0, 1)) * r.uniform(0.03, 0.08)  # some brown-warm, some blue-grey, most in between
		shades[k] = (v * (1 + warm), v * (1 + warm * 0.3), v * (1 - warm), 1.0)
	at = high.data.color_attributes.new(name, "FLOAT_COLOR", "POINT")
	mw = high.matrix_world
	for v in high.data.vertices:
		at.data[v.index].color = shades[owner[kd.find(mw @ v.co)[1]]]


def gradient_attr(o, name="grad"):
	"""0 at each piece's root, 1 at its tip (the point farthest from the piece's middle): for darker roots."""
	at = o.data.attributes.new(name, "FLOAT", "POINT")
	vs = o.data.vertices
	for idx in islands(o):
		mid = sum((vs[i].co for i in idx), Vector()) / len(idx)
		tip = max(idx, key=lambda i: (vs[i].co - mid).length)
		far = max((vs[i].co - vs[tip].co).length for i in idx) or 1.0
		for i in idx:
			at.data[i].value = 1.0 - (vs[i].co - vs[tip].co).length / far


def eye_attrs(o, look_for_side, shine_dir=(0.12, 0.0, 0.17)):
	"""For each eyeball (piece) of `o`: eye_t = how straight each point faces the way the eye looks (1 = the
	pupil's middle), eye_h = the same for the shine spot (up and to one side, the same on both eyes)."""
	t = o.data.attributes.new("eye_t", "FLOAT", "POINT")
	h = o.data.attributes.new("eye_h", "FLOAT", "POINT")
	vs = o.data.vertices
	for idx in islands(o):
		c = sum((vs[i].co for i in idx), Vector()) / len(idx)
		look = Vector(look_for_side(1 if c.x > 0 else -1)).normalized()
		hl = (look + Vector(shine_dir)).normalized()
		for i in idx:
			d = (vs[i].co - c).normalized()
			t.data[i].value = d.dot(look)
			h.data[i].value = d.dot(hl)


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
