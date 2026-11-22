// The dungeon ghosts' look (Claude, Nov 22, 2026): see-through in the middle, glowing at the edges, a dark hollow for
// the face with two bright eyes, and a misty tail that sways and fades away to nothing.
// The model's point colours steer it (tools/asset_forge/builds/ghost_body.py): red = how lit (0 in the face hollow),
// green = how far down the misty tail, blue = the eyes. The ghost's mace has no point colours: use_guide = false.
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_always, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.55, 0.95, 0.85, 1.0);
uniform vec4 eye_color : source_color = vec4(0.95, 1.0, 0.8, 1.0);
uniform float core : hint_range(0.0, 1.0) = 0.16;  // how solid the middle is
uniform float rim_power : hint_range(0.5, 6.0) = 2.0;  // how thin the glowing edge is
uniform float fade : hint_range(0.0, 1.0) = 1.0;  // 1 = here, 0 = gone into mist (teleport, death)
uniform bool use_guide = true;

varying vec3 guide;
varying vec3 wpos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
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

void vertex() {
	guide = use_guide ? COLOR.rgb : vec3(1.0, 0.0, 0.0);
	// the tail sways like smoke (more towards its tip)
	float m = guide.g * guide.g;
	VERTEX.x += sin(TIME * 2.3 + VERTEX.y * 7.0) * 0.035 * m;
	VERTEX.z += cos(TIME * 1.7 + VERTEX.y * 6.0) * 0.03 * m;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float n = noise(wpos * 6.0 + vec3(0.0, TIME * 0.6, 0.0));  // slow drifting mist inside
	float lit = guide.r;
	vec3 col = tint.rgb * (0.45 + 0.35 * n + rim * 1.3);
	float a = core + rim * 0.8 + 0.08 * n;
	// the face hollow: dark and nearly solid (you can't see through a ghost's face)
	col = mix(tint.rgb * 0.05, col, lit);
	a = mix(0.85, a, lit);
	// the misty tail: thins out and breaks up towards its tip
	a *= clamp(1.0 - guide.g * (0.55 + 0.6 * n), 0.0, 1.0);
	// the eyes
	if (guide.b > 0.5) {
		col = eye_color.rgb * 2.2;
		a = 1.0;
	} else if (guide.b > 0.01) {
		// scratch marks (owner, Nov 22: long, thin, pitch black; built in at 0.35, ghost_body.py)
		float sc = clamp(guide.b / 0.35, 0.0, 1.0);
		col = mix(col, vec3(0.0), sc);
		a = mix(a, 0.97, sc);
	}
	// fading into mist: it breaks up into drifting patches first
	a *= smoothstep(0.0, 0.35, fade - (1.0 - fade) * n);
	ALBEDO = col;
	ALPHA = clamp(a, 0.0, 1.0);
}
