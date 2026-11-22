// The ghosts' depth pass (Claude, Nov 22, 2026): drawn just before the ghost shader (src/art/ghost.gdshader, which has
// this as its next_pass with a lower render_priority), invisible, it only marks the ghost's front-most surface. So the
// see-through body shows its outside only and never tears where it folds over itself (its sleeves, cape and belt).
// It sits 4 mm further back than the real surface, so the ghost's own colour pass always passes in front of it.
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_always, shadows_disabled;

uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform bool use_guide = true;

void vertex() {
	// the same smoky sway as the ghost shader (the two must line up exactly)
	float g = use_guide ? COLOR.g : 0.0;
	float m = g * g;
	VERTEX.x += sin(TIME * 2.3 + VERTEX.y * 7.0) * 0.035 * m;
	VERTEX.z += cos(TIME * 1.7 + VERTEX.y * 6.0) * 0.03 * m;
	vec3 v = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v += normalize(v) * 0.004;
	POSITION = PROJECTION_MATRIX * vec4(v, 1.0);
}

void fragment() {
	if (fade < 0.6) {
		discard;  // (fading into mist: let everything behind show through)
	}
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
