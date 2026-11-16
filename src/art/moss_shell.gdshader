// Fluffy moss (owner, cave-life plan batch 1): the moss cushion is drawn ~10 times, each copy ("shell") pushed a
// little further out. Each shell keeps only the dots where a moss strand is still that tall, so together they look
// like a soft fuzzy velvet. The shell number (0 = the cushion itself .. 1 = the tips) is in the vertex colour's alpha
// (CaveLife._shell_mesh). Per plant (MultiMesh custom data): x = how long the fuzz is (damp spots: longer).
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float fur_length = 0.026;     // metres, at the tips (before the plant's own size)
uniform float strand_density = 190.0; // strands per metre
uniform float droop = 0.35;           // tips bend down under their weight

varying vec3 base_pos;
varying float shell;

void vertex() {
	shell = COLOR.a;
	base_pos = VERTEX;
	float len = fur_length * max(INSTANCE_CUSTOM.x, 0.2);
	VERTEX += NORMAL * len * shell;
	VERTEX.y -= len * droop * shell * shell;
}

float hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	vec3 q = base_pos * strand_density;
	vec3 cell = floor(q);
	vec3 f = fract(q) - 0.5;
	float h = 0.35 + 0.65 * hash3(cell);       // this strand's height
	float r = length(f);
	float thick = 0.55 * (1.0 - 0.65 * shell / h);  // strands get a little thinner toward their soft tips
	// Far away a strand is smaller than a pixel and would sparkle: fill the gaps in, it becomes a soft cushion.
	float blur = clamp(length(fwidth(q)) * 0.9 - 0.25, 0.0, 1.0);
	if (shell > 0.001 && (shell > h + blur || r > thick + blur)) {
		discard;
	}
	vec3 col = texture(albedo_tex, UV).rgb * COLOR.rgb;
	float tip = mix(1.0, hash3(cell + 7.0), 0.25);     // strands differ a little
	ALBEDO = col * mix(0.32, 1.12, shell) * tip;       // dark deep inside, bright fuzzy tips
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	RIM = 0.55;                                        // velvet: soft light along the edges
	RIM_TINT = 0.7;
	BACKLIGHT = col * 0.25 * shell;
}
