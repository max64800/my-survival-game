// Cave puddles (owner, Nov 18, F190: "water: puddles"). A flat sheet of still, dark water just above the floor: the
// floor's bumps poke through it, so its edge is the rock's own shape. Faint slow ripples all the time; under a water drip,
// rings spread from where the drops land (the drips fall about twice a second).
shader_type spatial;
render_mode cull_disabled;

uniform float drip = 0.0;  // 1 = a drip falls in the middle of this puddle
uniform float radius = 1.0;  // metres (the disc's size)

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0 * radius;  // metres from the middle
	float d = length(uv);
	float edge = 1.0 - smoothstep(radius * 0.8, radius, d);  // the disc fades out at its rim (the rock takes over)
	// slow ripples: two crossing wave sets
	vec2 w = vec2(sin(uv.x * 3.1 + TIME * 0.9) + sin(uv.y * 2.7 - TIME * 0.7), cos(uv.x * 2.3 - TIME * 0.8) + cos(uv.y * 3.4 + TIME * 0.6)) * 0.04;
	// drop rings from the middle, one about every 0.55 s, spreading and fading
	if (drip > 0.5) {
		for (int k = 0; k < 3; k++) {
			float t = fract(TIME / 1.65 + float(k) / 3.0);
			float ring = d - t * 0.9 * radius;
			float r = exp(-ring * ring * 160.0) * (1.0 - t);
			w += normalize(uv + 0.0001) * r * 0.5;
		}
	}
	NORMAL_MAP = normalize(vec3(w * 0.5 + 0.5, 1.0));
	NORMAL_MAP_DEPTH = 1.0;
	ALBEDO = vec3(0.02, 0.03, 0.035);
	ROUGHNESS = 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	ALPHA = 0.8 * edge;
}
