shader_type spatial;
// The shared look for everything that isn't terrain: props, stations, building pieces,
// monsters, drops. Made by Look.mat() (src/art/look.gd); don't set it up by hand.
//
// - The object's colour, with a grey hand-painted grain on top (stone, wood, fungus,
//   cloth, leather, metal, bark, smooth). Grey = only light/dark detail, colour stays.
// - The grain is projected from 3 sides in the object's own space ("triplanar"),
//   so it sticks to moving things (monsters) instead of sliding over them.
// - "wobble" pushes the corners around a little, so perfect balls and tubes look lumpy and hand-made.
// - A soft rim light on the edges: shapes read clearly in the dark.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2DArray detail_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normal_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float layer = 0.0;
uniform float detail_strength = 1.0;
uniform float tex_scale = 1.4;  // grain repeats per metre (object space)
uniform float roughness = 0.85;
uniform float metallic = 0.0;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float wobble = 0.0;      // metres of lumpiness
uniform float rim = 0.25;

varying vec3 v_pos;
varying vec3 v_n;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	if (wobble > 0.0) {
		// Same position -> same push, so the faces of a box never crack apart.
		vec3 q = VERTEX * 3.1;  // only the shape's own corners: moving things keep their shape
		VERTEX += (vec3(vnoise(q), vnoise(q + 17.3), vnoise(q + 31.7)) - 0.5) * 2.0 * wobble;
	}
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec3 n = normalize(v_n);
	vec3 bw = pow(abs(n), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 p = v_pos * tex_scale;
	float d = texture(detail_tex, vec3(p.zy, layer)).r * bw.x
		+ texture(detail_tex, vec3(p.xz, layer)).r * bw.y
		+ texture(detail_tex, vec3(p.xy, layer)).r * bw.z;
	vec3 tx = texture(normal_tex, vec3(p.zy, layer)).xyz * 2.0 - 1.0;
	vec3 ty = texture(normal_tex, vec3(p.xz, layer)).xyz * 2.0 - 1.0;
	vec3 tz = texture(normal_tex, vec3(p.xy, layer)).xyz * 2.0 - 1.0;
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	vec3 bent = normalize(tx.zyx * bw.x + ty.xzy * bw.y + tz.xyz * bw.z);
	bent = normalize(mix(n, bent, detail_strength));

	ALBEDO = albedo.rgb * mix(1.0, d * 2.0, detail_strength);
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission_color * emission_energy;
	NORMAL = normalize(mat3(VIEW_MATRIX) * (MODEL_NORMAL_MATRIX * bent));
	RIM = rim;
	RIM_TINT = 0.5;
}
