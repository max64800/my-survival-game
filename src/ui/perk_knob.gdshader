shader_type canvas_item;
// A perk's picture cut to a round knob (passive) or a diamond (active), with a coloured ring.
// Locked perks are grey and dark (skills window, owner's mock-up Nov 19).

uniform bool diamond = false;
uniform bool locked = false;
uniform vec4 ring : source_color = vec4(0.91, 0.66, 0.24, 1.0);
uniform float ring_width = 0.1;
uniform vec4 fill : source_color = vec4(0.05, 0.043, 0.035, 1.0);

void fragment() {
	vec2 p = abs(UV - 0.5) * 2.0;
	float d = diamond ? (p.x + p.y) : length(p);
	float aa = max(fwidth(d) * 1.2, 0.001);
	float inside = 1.0 - smoothstep(1.0 - aa, 1.0, d);
	float on_ring = smoothstep(1.0 - ring_width - aa, 1.0 - ring_width, d);
	vec4 tex = texture(TEXTURE, UV);
	if (locked) {
		float g = dot(tex.rgb, vec3(0.3, 0.59, 0.11));
		tex.rgb = mix(vec3(g), tex.rgb, 0.15) * 0.42;
	}
	vec3 col = mix(fill.rgb, tex.rgb, tex.a);
	col = mix(col, ring.rgb, on_ring);
	COLOR = vec4(col, inside * COLOR.a);
}
