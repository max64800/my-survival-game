// Firefly swarms (owner, Nov 18). The graphics card places every firefly (before: the game moved 650 of them one by one
// each frame, 5-6 ms, half the frame). The game only sends the swarm's flight path: 17 points from its head back along
// the trail it really flew, with the way it was heading at each. Each firefly keeps its own place along that path and
// round it (instance custom data), wobbles a little, and blinks on its own beat.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_never;

uniform vec3 pts[17];
uniform vec3 fws[17];
uniform vec3 tint : source_color = vec3(1.0, 0.8, 0.3);
uniform float fade = 1.0;
uniform float radius = 0.45;

varying float v_alpha;

void vertex() {
	float s = INSTANCE_CUSTOM.x;          // 0 = the head, 1 = the tail end
	vec2 o = INSTANCE_CUSTOM.yz;          // its place round the path (-1..1)
	float w = INSTANCE_CUSTOM.w;          // its own random number
	float bf = s * 16.0;
	int b0 = min(int(bf), 15);
	float f = bf - float(b0);
	vec3 centre = mix(pts[b0], pts[b0 + 1], f);
	vec3 fw = mix(fws[b0], fws[b0 + 1], f);
	fw = length(fw) > 0.01 ? normalize(fw) : vec3(0.0, 0.0, -1.0);
	vec3 side = abs(fw.y) < 0.95 ? normalize(cross(fw, vec3(0.0, 1.0, 0.0))) : vec3(1.0, 0.0, 0.0);
	vec3 up = cross(side, fw);
	float spread = radius * (1.0 - 0.75 * s);  // wide at the front, thin at the tail
	vec3 wobble = vec3(sin(TIME * 1.3 + w), sin(TIME * 1.7 + w * 1.3), cos(TIME * 1.1 + w)) * 0.12;
	// a firefly's blink: mostly dim, then a short bright flash, each on its own beat
	float beat = fract(TIME * (0.35 + 0.25 * fract(w)) + w);
	float glow = 0.15 + 0.85 * clamp(1.0 - abs(beat - 0.5) * 6.0, 0.0, 1.0);
	float sc = 0.7 + 0.5 * glow;
	VERTEX = VERTEX * sc + centre + (side * o.x + up * o.y) * spread + wobble;  // (node and instances sit at the origin)
	v_alpha = (0.5 + 0.5 * glow) * fade;
}

void fragment() {
	ALBEDO = tint;
	ALPHA = v_alpha;
}
