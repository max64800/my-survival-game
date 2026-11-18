// The swoosh behind a swing (WeaponTrail). UV.x: 0 = the blade now .. 1 = the oldest end; UV.y: 0 = near the hand,
// 1 = the tip. A slash pattern (streaks along the arc) times a soft mask that pans along it, so it flows with the swing;
// brightest at the tip, see-through near the hand. COLOR.a: the tail's fade (set by WeaponTrail).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.95, 0.85, 0.5);
uniform float pan = 0.0;

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float streaks = 0.78 + 0.22 * sin(v * 47.0 + sin(v * 11.0) * 2.0);       // fine lines running along the arc (soft: not stripes)
	float flow = 0.65 + 0.35 * sin((u * 14.0 - pan) + v * 5.0);              // a soft mask panning along it
	float edge = smoothstep(0.0, 0.55, v) * (1.0 - 0.35 * smoothstep(0.9, 1.0, v));
	ALBEDO = tint.rgb * (0.65 + 0.7 * v);
	ALPHA = clamp(COLOR.a * tint.a * edge * streaks * flow * 1.6, 0.0, 1.0);
}
