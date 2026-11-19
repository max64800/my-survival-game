// Root curtains (owner, Nov 17, F189): thin roots hanging across a tunnel mouth. Each strand hangs from its top (the
// model's origin) down its -Y; it sways a little in the cave air, and swings aside when a dwarf walks through it,
// its free end most. Only looks: no physics, every computer bends it for the dwarfs it can see.
// pushers[] = up to 4 dwarfs' feet (w = 1 when used), set each frame by RootCurtains.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform vec4 pushers[4];
// Only the strands a dwarf really touches move, gently (owner, Nov 19: standing at a curtain to break a strand bent the
// whole patch together: the push reached 75 cm and was strong).
uniform float push_reach = 0.4;  // metres round a dwarf's body
uniform float push_strength = 0.35;

void vertex() {
	vec3 top = MODEL_MATRIX[3].xyz;
	vec3 down = -MODEL_MATRIX[1].xyz;
	float len = length(down);  // the strand's length (its mesh is 1 m, scaled)
	down /= len;
	float h = clamp(dot(VERTEX - top, down) / len, 0.0, 1.0);  // 0 at the top, 1 at the free end
	float bend = h * h;
	vec3 off = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		if (pushers[i].w < 0.5) {
			continue;
		}
		vec3 body = pushers[i].xyz + vec3(0.0, 0.9, 0.0);  // about the middle of a dwarf
		vec3 here = top + down * len * h;
		vec3 d = here - body;
		float tall = abs(d.y);
		d.y = 0.0;
		float dist = length(d);
		float k = (1.0 - smoothstep(push_reach * 0.4, push_reach, dist)) * (1.0 - smoothstep(0.6, 1.3, tall));
		vec3 away = dist > 0.01 ? d / dist : vec3(1.0, 0.0, 0.0);
		off += away * k * push_strength * (0.4 + 0.6 * h);
	}
	float t = TIME * 0.7 + top.x * 1.9 + top.z * 1.4;  // each strand its own slow sway
	off += vec3(sin(t), 0.0, sin(t * 0.77 + 1.1)) * len * 0.035 * bend;
	VERTEX += off * (0.3 + 0.7 * bend);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * 2.2;  // coloured strands (alpha below 1) glow softly, like crystals
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	BACKLIGHT = COLOR.rgb * 0.25;
}
