// Pale cave grass and small ferns (owner, cave-life plan batch 1): they lean away from every dwarf walking through
// them and spring back after, and breathe a little in the cave air. Only looks: no physics, every computer bends them
// for the dwarfs it can see. pushers[] = up to 4 dwarfs' feet (w = 1 when used), set each frame by CaveLife.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float plant_height = 0.25;  // the model's height in metres (before the plant's own size)
uniform float push_reach = 0.9;     // metres round a dwarf's feet
uniform float push_strength = 1.15; // how far the tips move away, in plant heights (owner F198: twice as far as before)
uniform float push_scale = 1.0;     // stiff things (small roots) move less
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform float use_normal = 0.0;
uniform float tinted = 1.0;         // 1 = multiply by each plant's colour
uniform vec4 pushers[4];

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 up_axis = MODEL_MATRIX[1].xyz;
	float sc = length(up_axis);
	up_axis /= sc;
	float tall = plant_height * sc;
	float h = clamp(dot(VERTEX - origin, up_axis) / tall, 0.0, 1.3);
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
		float wob = sin(TIME * 9.0 + origin.x * 3.1 + origin.z * 2.3) * 0.22;
		off += (away * (1.0 + wob) + cross(away, vec3(0.0, 1.0, 0.0)) * wob * 0.6) * k * tall * push_strength;
		off.y -= k * tall * push_strength * 0.45;
	}
	float t = TIME * 0.8 + origin.x * 1.7 + origin.z * 1.3;  // a slow breath of air, each plant its own beat
	off += vec3(sin(t), 0.0, sin(t * 0.83 + 1.3)) * tall * 0.05;
	VERTEX += off * bend * push_scale;
}

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb * mix(vec3(1.0), COLOR.rgb, tinted);
	if (use_normal > 0.5) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	BACKLIGHT = c * 0.4 * tinted;  // thin blades and leaves let the lantern light shine through (not bark)
}
