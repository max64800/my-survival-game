// The broken rock's chunks (owner, Nov 18: "they have no texture, can we add the texture"): painted with the cave's own
// rock pictures (the same texture arrays as terrain.gdshader), projected from 3 sides in the chunk's own space, so the
// pattern tumbles with the chunk.
shader_type spatial;
render_mode cull_disabled;  // (both sides: no holes whichever way a face turned out)

uniform sampler2DArray albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normal_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float slice = 0.0;  // material * 4 + look (terrain.gdshader LOOKS)
uniform float tex_scale = 0.9;  // one texture tile about every 1 m of chunk
uniform vec3 tint = vec3(1.0);
instance uniform float chunk_size = 0.3;  // the chunk's size (its mesh is 1 m): the pattern keeps its real size

varying vec3 v_local;
varying vec3 v_lnormal;

void vertex() {
	v_local = VERTEX * chunk_size * tex_scale;
	v_lnormal = NORMAL;
}

void fragment() {
	vec3 bw = pow(abs(v_lnormal), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 a = texture(albedo_tex, vec3(v_local.zy, slice)).rgb * bw.x
		+ texture(albedo_tex, vec3(v_local.xz, slice)).rgb * bw.y
		+ texture(albedo_tex, vec3(v_local.xy, slice)).rgb * bw.z;
	ALBEDO = a * tint;
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
}
