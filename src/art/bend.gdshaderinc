// Shared by plant_bend.gdshader (grass, ferns, small roots) and mushroom_bend.gdshader (little mushrooms, F219):
// the plant leans away from every dwarf walking through it and springs back after, and breathes a little in the cave
// air. Only looks: no physics, every computer bends it for the dwarfs it can see.
// pushers[] = up to 4 dwarfs' feet (w = 1 when used), set each frame by CaveLife / GlowField.
// Needs render_mode world_vertex_coords.

uniform float plant_height = 0.25;  // the model's height in metres (before the plant's own size)
uniform float push_reach = 0.9;     // metres round a dwarf's feet
uniform float push_strength = 1.15; // how far the tips move away, in plant heights (owner F198: twice as far as before)
uniform float push_scale = 1.0;     // stiff things (small roots, mushrooms) move less
uniform vec4 pushers[4];

vec3 bend_offset(vec3 vertex, vec3 origin, vec3 up_axis_scaled, float time) {
	float sc = length(up_axis_scaled);
	vec3 up_axis = up_axis_scaled / sc;
	float tall = plant_height * sc;
	float h = clamp(dot(vertex - origin, up_axis) / tall, 0.0, 1.3);
	float bend = h * h;  // the base stays put, the tips move most
	vec3 off = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		if (pushers[i].w < 0.5) {
			continue;
		}
		vec3 d = origin - pushers[i].xyz;
		float below = d.y;
		d.y = 0.0;
		float dist = length(d);
		float k = (1.0 - smoothstep(push_reach * 0.25, push_reach, dist)) * (1.0 - smoothstep(0.8, 1.6, abs(below)));
		vec3 away = dist > 0.01 ? d / dist : vec3(1.0, 0.0, 0.0);
		// pushed away, with a quick wobble while a dwarf is in it (it springs about, then settles as they leave)
		float wob = sin(time * 9.0 + origin.x * 3.1 + origin.z * 2.3) * 0.22;
		off += (away * (1.0 + wob) + cross(away, vec3(0.0, 1.0, 0.0)) * wob * 0.6) * k * tall * push_strength;
		off.y -= k * tall * push_strength * 0.45;
	}
	float t = time * 0.8 + origin.x * 1.7 + origin.z * 1.3;  // a slow breath of air, each plant its own beat
	off += vec3(sin(t), 0.0, sin(t * 0.83 + 1.3)) * tall * 0.05;
	return off * bend * push_scale;
}
