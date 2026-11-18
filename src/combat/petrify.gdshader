// A dead creature turning to stone (owner, Nov 18): drawn on top of its own paint (material_overlay). Dark cracks run
// out from its middle first, then grey stone fills in behind them, until it is a solid stone statue. `progress` 0 -> 1.
// `damage` (0 -> 1, each pickaxe hit) deepens and widens the cracks.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_disabled;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform vec3 seed_pos = vec3(0.0);   // where it starts (world): the middle of the body
uniform float spread = 1.0;          // how far it has to spread (m)
uniform vec3 stone_light : source_color = vec3(0.47, 0.45, 0.42);
uniform vec3 stone_dark : source_color = vec3(0.31, 0.30, 0.28);
uniform vec3 crack_color : source_color = vec3(0.09, 0.08, 0.075);
uniform float wobble = 0.0;          // the part's own lumpiness (prop.gdshader): pushed the same, or the stone hides under it

varying vec3 wpos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	return 0.55 * noise(p) + 0.3 * noise(p * 2.1) + 0.15 * noise(p * 4.3);
}

// thin lines where the noise crosses its middle: a web of cracks
float cracks(vec3 p, float width) {
	float a = abs(noise(p * 9.0) - 0.5);
	float b = abs(noise(p * 17.0 + 3.1) - 0.5);
	return max(1.0 - smoothstep(0.0, width, a), 0.6 * (1.0 - smoothstep(0.0, width * 0.7, b)));
}

// (prop.gdshader's noise, exactly: the same corners must move the same way)
float whash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float wnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(whash(i + vec3(0, 0, 0)), whash(i + vec3(1, 0, 0)), f.x),
				   mix(whash(i + vec3(0, 1, 0)), whash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(whash(i + vec3(0, 0, 1)), whash(i + vec3(1, 0, 1)), f.x),
				   mix(whash(i + vec3(0, 1, 1)), whash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	if (wobble > 0.0) {
		vec3 q = VERTEX * 3.1;
		VERTEX += (vec3(wnoise(q), wnoise(q + 17.3), wnoise(q + 31.7)) - 0.5) * 2.0 * wobble;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = distance(wpos, seed_pos) / max(spread, 0.05);
	float edge = fbm(wpos * 4.0);
	float front = progress * 1.6 - d - edge * 0.35;          // > 0: already stone
	float stone = smoothstep(0.0, 0.12, front);
	float ahead = smoothstep(-0.35, 0.0, front) * (1.0 - stone); // the cracks run just ahead of the stone
	float cr = cracks(wpos, 0.035 + 0.05 * damage);
	vec3 col = mix(stone_dark, stone_light, fbm(wpos * 2.5));
	col = mix(col, crack_color, cr * (0.55 + 0.45 * damage) * stone);
	ALBEDO = mix(crack_color, col, stone);
	ALPHA = clamp(max(stone, ahead * cr), 0.0, 1.0);
	ROUGHNESS = 0.95;
}
