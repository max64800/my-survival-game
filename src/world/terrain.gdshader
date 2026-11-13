shader_type spatial;
// Colors the dig-anywhere rock. Each voxel has a material number (see mat.gd):
// 0 moss, 1 stone, 2 dirt, 3 copper ore, 4 border rock.
// The look: flat-shaded low-poly facets + soft color noise. No image textures yet.

uniform vec3 moss_color : source_color = vec3(0.24, 0.40, 0.17);
uniform vec3 stone_color : source_color = vec3(0.38, 0.35, 0.33);
uniform vec3 dirt_color : source_color = vec3(0.36, 0.25, 0.16);
uniform vec3 copper_color : source_color = vec3(0.78, 0.45, 0.22);
uniform vec3 border_color : source_color = vec3(0.13, 0.10, 0.17);
uniform vec3 border_glow : source_color = vec3(0.35, 0.18, 0.65);
uniform float flat_shading = 1.0;

varying vec4 v_indices;
varying vec4 v_weights;
varying vec3 v_world;

vec4 decode_8bit_vec4(float v) {
	uint i = floatBitsToUint(v);
	return vec4(float(i & 0xffu), float((i >> 8u) & 0xffu), float((i >> 16u) & 0xffu), float((i >> 24u) & 0xffu));
}

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

vec3 mat_color(float idx, vec3 wp, out vec3 emit) {
	float n = vnoise(wp * 0.9) * 0.5 + vnoise(wp * 0.23) * 0.5;
	emit = vec3(0.0);
	if (idx < 0.5) {
		return moss_color * (0.75 + 0.5 * n);
	} else if (idx < 1.5) {
		float strata = sin(wp.y * 1.7 + vnoise(wp * 0.15) * 4.0) * 0.5 + 0.5;
		return stone_color * (0.8 + 0.25 * n + 0.12 * strata);
	} else if (idx < 2.5) {
		return dirt_color * (0.8 + 0.4 * n);
	} else if (idx < 3.5) {
		float speck = step(0.86, vnoise(wp * 3.1));
		emit = copper_color * speck * 0.35;
		return mix(stone_color * 0.8, copper_color, 0.55 + 0.45 * n);
	} else {
		float vein = smoothstep(0.78, 0.86, vnoise(wp * 0.6));
		emit = border_glow * vein * 0.8;
		return border_color * (0.8 + 0.3 * n);
	}
}

void vertex() {
	v_indices = decode_8bit_vec4(CUSTOM1.x);
	v_weights = decode_8bit_vec4(CUSTOM1.y) / 255.0;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 w = v_weights / (v_weights.x + v_weights.y + v_weights.z + v_weights.w + 0.00001);
	vec3 e0; vec3 e1; vec3 e2; vec3 e3;
	vec3 col = mat_color(v_indices.x, v_world, e0) * w.x
		+ mat_color(v_indices.y, v_world, e1) * w.y
		+ mat_color(v_indices.z, v_world, e2) * w.z
		+ mat_color(v_indices.w, v_world, e3) * w.w;
	ALBEDO = col;
	EMISSION = e0 * w.x + e1 * w.y + e2 * w.z + e3 * w.w;
	ROUGHNESS = 0.92;
	if (flat_shading > 0.5) {
		NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	}
}
