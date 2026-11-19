// Little cave waterfalls (owner, Nov 19: "little waterfalls, not just the dripstones... the water just flows through
// some cracks, down"). A thin ribbon of water running down the rock face: streaks of light sliding downward, thinner and
// fainter at its sides, starting thin at the crack and spreading a little as it falls. UV.y = metres down from the top,
// UV.x = 0..1 across. Slightly glowing so it catches the eye in the dark, glossy where the lantern hits it.
shader_type spatial;
render_mode cull_disabled, depth_draw_never;

uniform float length = 4.0;  // metres from the crack to the floor
uniform float speed = 1.6;  // how fast the water slides down (m/s)

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float down = UV.y;
	float across = UV.x;
	float flow = down - TIME * speed;
	// thin streams side by side, each wavering a little, sliding down at their own pace
	float streaks = vnoise(vec2(across * 9.0 + sin(down * 1.7) * 0.4, flow * 1.3));
	streaks += 0.6 * vnoise(vec2(across * 21.0, flow * 3.1 + 7.0));
	streaks = smoothstep(0.55, 1.45, streaks);
	float sides = smoothstep(0.0, 0.3, across) * smoothstep(1.0, 0.7, across);
	float ends = smoothstep(0.0, 0.6, down) * smoothstep(length, length - 0.2, down);  // seeping out of the crack
	vec3 water = vec3(0.45, 0.66, 0.82);  // (round 2: bluer, more see-through, a softer shine)
	ALBEDO = water * (0.3 + 0.7 * streaks);
	EMISSION = water * (0.12 + 0.35 * streaks);  // (round 3: glows enough to spot from across the cave)
	ROUGHNESS = 0.18;
	SPECULAR = 0.5;
	ALPHA = clamp((0.15 + 0.6 * streaks) * sides * ends, 0.0, 1.0);
}
