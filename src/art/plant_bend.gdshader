// Pale cave grass and small ferns (owner, cave-life plan batch 1): they lean away from every dwarf walking through
// them and spring back after (the bend itself: bend.gdshaderinc, shared with the little mushrooms).
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

#include "res://src/art/bend.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform float use_normal = 0.0;
uniform float tinted = 1.0;         // 1 = multiply by each plant's colour

void vertex() {
	VERTEX += bend_offset(VERTEX, MODEL_MATRIX[3].xyz, MODEL_MATRIX[1].xyz, TIME);
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
