// Shiny, mirror-like crystal (owner, Nov 16: "different shine depending on where you stand, hard edges" and then
// "they're matte: make them shiny, a bit like a mirror, cool and expensive").
// A cave has almost nothing for glass to reflect, so each flat facet reflects a made-up cave instead: dark below,
// warm lantern-lit rock above with bands like cave walls, and a few bright lights. Walk round and every facet shows a
// different piece of it, some dark, some flashing white. Like real glass, a face seen side-on is a full mirror
// (fresnel); flashes split into a little rainbow (the "fire" of a cut gem); real lights (your lantern) make sharp
// highlights. The narrow cut edges sit at their own angle, so they flash as hard lines.
// The painted picture (cave_plants.py: pale, with cracks, cloud and bubbles) is tinted with the kind's colour.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float glow = 0.2;    // how much it shines by itself (kept low: a mirror needs dark glass to show off)
uniform float shine = 2.2;    // how bright the flashes are
uniform float mirror = 1.0;   // how strongly it reflects the made-up cave

// Bright lights in the made-up surroundings (world directions).
float fake_lights(vec3 r) {
	float s = 0.0;
	s += pow(max(dot(r, normalize(vec3(0.55, 0.62, 0.32))), 0.0), 60.0);
	s += pow(max(dot(r, normalize(vec3(-0.7, 0.35, 0.45))), 0.0), 45.0) * 0.8;
	s += pow(max(dot(r, normalize(vec3(0.1, 0.3, -0.95))), 0.0), 70.0) * 0.9;
	s += pow(max(dot(r, normalize(vec3(-0.3, 0.9, -0.3))), 0.0), 30.0) * 0.6;
	s += pow(max(dot(r, normalize(vec3(0.8, -0.1, -0.55))), 0.0), 40.0) * 0.5;
	// many small sparkles all round, so some facet always catches one wherever you stand
	float w = 0.5 + 0.5 * sin(r.x * 7.3 + 1.1) * sin(r.y * 5.9 + 0.4) * sin(r.z * 6.7 + 2.3);
	s += pow(w, 18.0) * 1.4;
	return s;
}

// The made-up cave a facet reflects: near-black floor, warm rock above, broken into bands like cave walls.
vec3 fake_cave(vec3 r) {
	vec3 low = vec3(0.01, 0.012, 0.018);
	vec3 high = vec3(0.95, 0.8, 0.62);
	vec3 c = mix(low, high, smoothstep(-0.35, 0.85, r.y));
	float bands = 0.5 + 0.5 * sin(r.x * 4.1 + r.z * 3.3) * sin(r.y * 6.2 + 1.0);
	return c * (0.15 + 1.3 * pow(bands, 1.5));
}

// Each crystal slowly lights up and fades on its own (owner, Nov 17): one breath every 3 to 10 seconds, its length and
// start from where it sits. GlowField.crystal_pulse() is the same sum, so its light on the rock breathes along.
float crystal_pulse(vec3 o, float t) {
	float period = 3.0 + 7.0 * fract(o.x * 0.137 + o.y * 0.271 + o.z * 0.419);
	float phase = fract(o.x * 0.71 + o.y * 0.29 + o.z * 0.53);
	float p = 0.5 - 0.5 * cos(6.2831853 * (t / period + phase));
	return p * p * (3.0 - 2.0 * p);
}

void fragment() {
	vec3 paint = texture(albedo_tex, UV).rgb;
	vec3 col = paint * tint.rgb;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 r = reflect(-v, n);
	// a mirror shows its surroundings sliding across it as you move: bend the reflection a little by where on the
	// crystal this point is, so streaks run across each face instead of one flat colour
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	r = normalize(r + 0.35 * vec3(sin(wp.y * 5.0 + wp.x * 2.0), 0.4 * sin(wp.x * 3.0 - wp.z * 4.0), cos(wp.y * 4.0 - wp.z * 3.0)));
	float facing = clamp(dot(n, v), 0.0, 1.0);
	float fres = 0.5 + 0.5 * pow(1.0 - facing, 3.0);  // glass: some mirror face-on, full mirror side-on
	float flash = fake_lights(r);
	// dark, glossy glass: real lights (the lantern) give sharp highlights
	ALBEDO = col * 0.12;
	ROUGHNESS = 0.03;
	METALLIC = 0.6;
	SPECULAR = 1.0;
	// light from inside, brighter on facets turned toward you
	vec3 inner = col * glow * (0.15 + 0.85 * facing * facing);
	float breath = crystal_pulse(MODEL_MATRIX[3].xyz, TIME);
	inner *= 5.0 * breath * breath;  // all the way down to no glow (you still see the crystal), then much brighter (owner, round 2)
	// the reflection: the made-up cave, tinted a little by the crystal's colour (coloured glass)
	vec3 cave = fake_cave(r) * mix(vec3(1.0), tint.rgb, 0.55) * fres * mirror;
	// flashes: white-hot, split into a little rainbow at their edge (a cut gem's fire)
	vec3 fire = 0.6 + 0.4 * cos(6.2832 * (dot(r, vec3(1.7, 2.3, 1.1)) + vec3(0.0, 0.33, 0.67)));
	vec3 flashes = mix(fire * tint.rgb * 1.5, vec3(1.0), clamp(flash - 0.3, 0.0, 1.0)) * flash * shine;
	EMISSION = inner + cave + flashes;
}
